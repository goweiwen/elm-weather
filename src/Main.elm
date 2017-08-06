port module Main exposing (..)

import Html exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field)
import String exposing (slice, toInt)
import Result exposing (toMaybe)
import Maybe exposing (withDefault)
import Date exposing (Month(..))
import Date.Extra
import Credentials exposing (apiKey)

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }

port title : String -> Cmd a

-- Model

type alias Model =
    { weather : Weather
    , json: String
    }

init : (Model, Cmd Msg)
init =
    ( Model
          (Weather [])
          ""
    , Cmd.batch
        [ title "Weather"
        , getWeather
        ]
    )


-- Update

type Msg = GetWeather
         | UpdateWeather (Result Http.Error Weather)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        GetWeather ->
            (model, getWeather)
        UpdateWeather (Ok weather) ->
            ( { model | weather = weather }, Cmd.none )
        UpdateWeather (Err (Http.BadPayload m r)) ->
            ( { model | json = m }, Cmd.none )
        UpdateWeather (Err _) ->
            (model, Cmd.none)

getWeather : Cmd Msg
getWeather =
    Http.request
        { method = "GET"
        , headers = [Http.header "api-key" apiKey]
        , url = "https://api.data.gov.sg/v1/environment/24-hour-weather-forecast"
        , body = Http.emptyBody
        , expect = Http.expectJson decodeWeather
        -- , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send UpdateWeather 

type alias Weather =
    { periods : List Period
    }

type alias Period =
    { time : Time
    , regions : Regions
    }

type alias Time =
    { start : String
    , end : String
    }

type alias Regions =
    { west : String
    , east : String
    , central : String
    , south : String
    , north : String
    }

decodeWeather : Decoder Weather
decodeWeather =
    Decode.map Weather
        (field "items" <| Decode.index 0
             (field "periods" <| Decode.list decodePeriod)
        )

decodePeriod : Decoder Period
decodePeriod =
    Decode.map2 Period
        (field "time" decodeTime)
        (field "regions" decodeRegions)

decodeTime : Decoder Time
decodeTime =
    Decode.map2 Time
        (field "start" Decode.string)
        (field "end" Decode.string)

decodeRegions : Decoder Regions
decodeRegions =
    Decode.map5 Regions
        (field "west" Decode.string)
        (field "east" Decode.string)
        (field "central" Decode.string)
        (field "south" Decode.string)
        (field "north" Decode.string)

-- View

view : Model -> Html Msg
view model =
    div [] [
        p [] [ text model.json ]
        , table [] [
            thead [] (viewHeader :: List.map viewPeriod model.weather.periods)
        ]
    ]

viewHeader : Html Msg
viewHeader =
    tr [] [
         th [] [text "Time"],
         th [] [text "West"],
         th [] [text "East"],
         th [] [text "Central"],
         th [] [text "South"],
         th [] [text "North"]
        ]

viewPeriod : Period -> Html Msg
viewPeriod period =
    tr [] [
         td [] [text <| formatDateTime period.time.start],
         td [] [text period.regions.west],
         td [] [text period.regions.east],
         td [] [text period.regions.central],
         td [] [text period.regions.south],
         td [] [text period.regions.north]
        ]

-- 2017-08-06T12:00:00+08:00
formatDateTime : String -> String
formatDateTime dateTime =
    let year = slice 0 4 dateTime |> toInt |> toMaybe |> withDefault 0
        month = slice 5 7 dateTime |> toInt |> toMaybe |> withDefault 0
        day = slice 9 10 dateTime |> toInt |> toMaybe |> withDefault 0
        hour = slice 11 12 dateTime |> toInt |> toMaybe |> withDefault 0
    in Date.Extra.fromParts year (getMonth month) day hour 0 0 0
       |> Date.Extra.toFormattedString "H:mm d MMM"

getMonth x = case x of
              1 -> Jan
              2 -> Feb
              3 -> Mar
              4 -> Apr
              5 -> May
              6 -> Jun
              7 -> Jul
              8 -> Aug
              9 -> Sep
              10 -> Oct
              11 -> Nov
              12 -> Dec
              _ -> Jan

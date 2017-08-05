import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field)
import Credentials exposing (apiKey)

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }

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
    , Cmd.none )


-- Update

type Msg = GetWeather
         | UpdateWeather (Result Http.Error String)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        GetWeather ->
            (model, getWeather)
        UpdateWeather (Ok weather) ->
            ( { model | json = weather }, Cmd.none )
        UpdateWeather (Err _) ->
            (model, Cmd.none)

getWeather : Cmd Msg
getWeather =
    Http.request
        { method = "GET"
        , headers = [Http.header "api-key" apiKey]
        , url = "https://api.data.gov.sg/v1/environment/24-hour-weather-forecast"
        , body = Http.emptyBody
        -- , expect = Http.expectJson decodeWeather
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send UpdateWeather 

type alias Weather =
    { items : List Item
    }

type alias Item =
    { periods : List Period
    }

type alias Period =
    { time : Time
    , region : Region
    }

type alias Region =
    { west : String
    , east : String
    , central : String
    , south : String
    , north : String
    }

type alias Time =
    { start : String
    , end : String
    }

decodeWeather : Decoder Weather
decodeWeather =
    Decode.map Weather
        (field "items" <| Decode.list decodeItem)

decodeItem : Decoder Item
decodeItem =
    Decode.map Item
        (field "periods" <| Decode.list decodePeriod)

decodePeriod : Decoder Period
decodePeriod =
    Decode.map2 Period
        (field "time" decodeTime)
        (field "region" decodeRegion)

decodeTime : Decoder Time
decodeTime =
    Decode.map2 Time
        (field "start" Decode.string)
        (field "end" Decode.string)

decodeRegion : Decoder Region
decodeRegion =
    Decode.map5 Region
        (field "west" Decode.string)
        (field "east" Decode.string)
        (field "central" Decode.string)
        (field "south" Decode.string)
        (field "north" Decode.string)

-- View

view : Model -> Html Msg
view model =
    div [ class "container" ] [
        h1 [ class "h1" ] [ text "Weather" ]
        , p [ class "p" ] [
            button [ class "btn", onClick GetWeather ] [ text "Hot day, innit?" ]
        ]
        , p [ class "p" ] [ text model.json ]
        , case periods model.weather of
              Nothing -> div [] []
              Just val -> div [] (List.map (\x -> p [] [text x.region.central]) val)
    ]

periods : Weather -> Maybe (List Period)
periods weather =
    let item = List.head weather.items
    in Maybe.map .periods item

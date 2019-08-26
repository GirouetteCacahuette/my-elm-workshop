module Step08.CategoriesPage exposing (Model, Msg(..), RemoteData(..), init, main, update, view)

import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)
import Http exposing (expectString)
import Result exposing (Result)
import Utils.Utils exposing (styles, testsIframe)


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = displayTestsAndView
        , subscriptions = \model -> Sub.none
        }


type alias Model =
    { categories : RemoteData String
    }


type Msg
    = OnCategoriesFetched (Result Http.Error String)


type alias Category =
    { id : Int
    , name : String
    }


type RemoteData a
    = Loading
    | Loaded a
    | OnError


init : ( Model, Cmd Msg )
init =
    ( Model Loading
    , Http.get
        { url = "https://opentdb.com/api_category.php"
        , expect =
            expectString
                OnCategoriesFetched
        }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnCategoriesFetched result ->
            ( case result of
                Ok cat ->
                    Model (Loaded cat)

                Err error ->
                    Model OnError
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Play within a given category" ]
        , text
            (case model.categories of
                Loading ->
                    "Loading the categories..."

                Loaded cat ->
                    cat

                OnError ->
                    "An error occurred while loading the categories"
            )
        ]



------------------------------------------------------------------------------------------------------
-- Don't modify the code below, it displays the view and the tests and helps with testing your code --
------------------------------------------------------------------------------------------------------


displayTestsAndView : Model -> Html Msg
displayTestsAndView model =
    div []
        [ styles
        , div [ class "jumbotron" ] [ view model ]
        , testsIframe
        ]

module Step14.Main exposing (Category, Model, Msg(..), Page(..), RemoteData(..), categoriesDecoder, displayCategoriesList, displayCategoriesPage, displayCategory, displayHomePage, displayView, getCategoriesRequest, getCategoriesUrl, init, main, update, view)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Navigation exposing (Key)
import Html exposing (Html, a, div, h1, h2, li, p, text, ul)
import Html.Attributes exposing (class, href)
import Http exposing (expectJson)
import Json.Decode as Decode
import Result exposing (Result)
import Step14.GamePage exposing (Game, Question)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>))
import Utils.Utils exposing (styles, testsIframe)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = displayView
        , subscriptions = always Sub.none
        , onUrlRequest = OnUrlRequest
        , onUrlChange = OnUrlChange
        }


type Msg
    = OnCategoriesFetched (Result Http.Error (List Category))
    | OnUrlRequest UrlRequest
    | OnUrlChange Url
    | OnQuestionsFetched (Result Http.Error (List Question))


type Page
    = HomePage
    | CategoriesPage (RemoteData (List Category))
    | ResultPage Int
    | GamePage (RemoteData Game)


type Route
    = HomeRoute
    | CategoriesRoute
    | ResultRoute Int
    | GameRoute


type alias Model =
    { key : Key
    , page : Page
    }


type alias Category =
    { id : Int, name : String }


type RemoteData a
    = Loading
    | Loaded a
    | OnError


routeParser : Parser.Parser (Route -> Route) Route
routeParser =
    Parser.oneOf
        [ Parser.map HomeRoute Parser.top
        , Parser.map CategoriesRoute (Parser.s "categories")
        , Parser.map ResultRoute (Parser.s "result" </> Parser.int)
        , Parser.map GameRoute (Parser.s "game")
        ]


parseUrlToPageAndCommand : Url -> ( Page, Cmd Msg )
parseUrlToPageAndCommand url =
    let
        routeMaybe : Maybe Route
        routeMaybe =
            Parser.parse routeParser { url | path = url.fragment |> Maybe.withDefault "", fragment = Nothing }
    in
    case routeMaybe of
        Just CategoriesRoute ->
            ( CategoriesPage Loading, getCategoriesRequest )

        Just (ResultRoute score) ->
            ( ResultPage score, Cmd.none )

        Just HomeRoute ->
            ( HomePage, Cmd.none )

        Just GameRoute ->
            ( GamePage Loading, getQuestionsRequest )

        Nothing ->
            ( HomePage, Cmd.none )


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        ( page, cmd ) =
            parseUrlToPageAndCommand url
    in
    ( Model key page, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnCategoriesFetched (Ok categories) ->
            case model.page of
                CategoriesPage _ ->
                    ( { model | page = CategoriesPage (Loaded categories) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        OnCategoriesFetched (Err err) ->
            case model.page of
                CategoriesPage _ ->
                    ( { model | page = CategoriesPage OnError }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        OnUrlRequest urlRequest ->
            case urlRequest of
                External url ->
                    ( model, Navigation.load url )

                Internal url ->
                    ( model, Navigation.pushUrl model.key (Url.toString url) )

        OnUrlChange url ->
            let
                ( page, cmd ) =
                    parseUrlToPageAndCommand url
            in
            ( { model | page = page }, cmd )

        OnQuestionsFetched (Ok (firstQuestion :: remainingQuestion)) ->
            case model.page of
                GamePage _ ->
                    ( { model | page = GamePage (Loaded (Game firstQuestion remainingQuestion)) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        OnQuestionsFetched _ ->
            case model.page of
                CategoriesPage _ ->
                    ( { model | page = CategoriesPage OnError }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


getCategoriesUrl : String
getCategoriesUrl =
    "https://opentdb.com/api_category.php"


categoriesDecoder : Decode.Decoder (List Category)
categoriesDecoder =
    Decode.map2 Category (Decode.field "id" Decode.int) (Decode.field "name" Decode.string)
        |> Decode.list
        |> Decode.field "trivia_categories"


getCategoriesRequest : Cmd Msg
getCategoriesRequest =
    Http.get
        { url = getCategoriesUrl
        , expect = expectJson OnCategoriesFetched categoriesDecoder
        }


getQuestionsRequest : Cmd Msg
getQuestionsRequest =
    Http.get
        { url = questionsUrl
        , expect = expectJson OnQuestionsFetched questionsDecoder
        }


questionsDecoder : Decode.Decoder (List Question)
questionsDecoder =
    Decode.field "results" (Decode.list questionDecoder)


questionsUrl : String
questionsUrl =
    "https://opentdb.com/api.php?amount=5&type=multiple"


questionDecoder : Decode.Decoder Question
questionDecoder =
    Decode.map3
        Question
        (Decode.field "question" Decode.string)
        correctAnswerDecoder
        answersDecoder


correctAnswerDecoder : Decode.Decoder String
correctAnswerDecoder =
    Decode.field "correct_answer" Decode.string


answersDecoder : Decode.Decoder (List String)
answersDecoder =
    Decode.map2
        (::)
        correctAnswerDecoder
        (Decode.field "incorrect_answers" (Decode.list Decode.string))


view : Model -> Html Msg
view model =
    div []
        [ case model.page of
            HomePage ->
                displayHomePage

            CategoriesPage categoriesModel ->
                displayCategoriesPage categoriesModel

            ResultPage score ->
                displayResultPage score

            GamePage questionsModel ->
                displayGamePage questionsModel
        ]


displayHomePage : Html Msg
displayHomePage =
    div [ class "gameOptions" ]
        [ h1 [] [ text "Quiz Game" ]
        , a [ class "btn btn-primary", href "#categories" ] [ text "Play from a category" ]
        , a [ class "btn btn-primary", href "#game" ] [ text "Play random questions" ]
        ]


displayResultPage : Int -> Html Msg
displayResultPage score =
    div [ class "score" ]
        [ h1 [] [ text ("Your score: " ++ String.fromInt score ++ " / 5") ]
        , a [ class "btn btn-primary", href "#" ] [ text "Replay" ]
        , p [] [ text (displayComment score) ]
        ]


displayComment : Int -> String
displayComment score =
    if score <= 3 then
        "Keep going, I'm sure you can do better!"

    else
        "Congrats, this is really good!"


displayCategoriesPage : RemoteData (List Category) -> Html Msg
displayCategoriesPage categories =
    div []
        [ h1 [] [ text "Play within a given category" ]
        , displayCategoriesList categories
        ]


displayGamePage : RemoteData Game -> Html Msg
displayGamePage gameRemote =
    case gameRemote of
        Loaded game ->
            div [ class "question" ]
                [ h2 [ class "question" ] [ text game.currentQuestion.question ]
                , ul [ class "answers" ]
                    (List.map
                        (\answer ->
                            li [] [ a [ class "btn btn-primary" ] [ text answer ] ]
                        )
                        game.currentQuestion.answers
                    )
                ]

        OnError ->
            div [] [ text "An unknown error occurred while loading the questions" ]

        Loading ->
            div [] [ text "Loading the questions..." ]


displayCategoriesList : RemoteData (List Category) -> Html Msg
displayCategoriesList categoriesRemote =
    case categoriesRemote of
        Loaded categories ->
            List.map displayCategory categories
                |> ul [ class "categories" ]

        OnError ->
            text "An error occurred while fetching categories"

        Loading ->
            text "Categories are loading..."


displayCategory : Category -> Html Msg
displayCategory category =
    let
        path =
            "#game/category/" ++ String.fromInt category.id
    in
    li []
        [ a [ class "btn btn-primary", href path ] [ text category.name ]
        ]



------------------------------------------------------------------------------------------------------
-- Don't modify the code below, it displays the view and the tests and helps with testing your code --
------------------------------------------------------------------------------------------------------


displayView : Model -> Document Msg
displayView model =
    Document
        "Step 14"
        [ styles
        , view model
        , testsIframe
        ]

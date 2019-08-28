module Step13.GamePage exposing (Category, Game, Model, Msg(..), Question, RemoteData(..), displayAnswer, displayTestsAndView, gamePage, init, main, questionsUrl, update, view)

import Browser
import Html exposing (Html, a, div, h2, li, text, ul)
import Html.Attributes exposing (class)
import Http exposing (Error, expectJson)
import Json.Decode as Decode exposing (field, list, map2, map3, string)
import Utils.Utils exposing (styles, testsIframe)


questionsUrl : String
questionsUrl =
    "https://opentdb.com/api.php?amount=5&type=multiple"


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = displayTestsAndView
        , subscriptions = \model -> Sub.none
        }


type alias Question =
    { question : String
    , correctAnswer : String
    , answers : List String
    }


type alias Model =
    { game : RemoteData Game
    }


type alias Game =
    { currentQuestion : Question
    , remainingQuestions : List Question
    }


type Msg
    = OnQuestionsFetched (Result Http.Error (List Question))


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
    ( Model Loading, getQuestionsRequest )


extractFirst : List Question -> Question
extractFirst questionsList =
    case List.head questionsList of
        Just question ->
            question

        Nothing ->
            Question "" "" []


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        OnQuestionsFetched questionsResult ->
            ( Model
                (case questionsResult of
                    Ok questions ->
                        Loaded (Game (extractFirst questions) (List.drop 1 questions))

                    Err error ->
                        OnError
                )
            , Cmd.none
            )


getQuestionsRequest : Cmd Msg
getQuestionsRequest =
    Http.get { url = getQuestionsUrl, expect = expectJson OnQuestionsFetched getQuestionsDecoder }


getQuestionsUrl : String
getQuestionsUrl =
    "https://opentdb.com/api.php?amount=5&type=multiple"


getQuestionsDecoder : Decode.Decoder (List Question)
getQuestionsDecoder =
    Decode.field "results" questionsListDecoder


questionsListDecoder : Decode.Decoder (List Question)
questionsListDecoder =
    Decode.list questionDecoder


questionDecoder : Decode.Decoder Question
questionDecoder =
    map3 Question
        (field "question" string)
        (field "correct_answer" string)
        (map2
            (\correct_answer incorrect_answers -> correct_answer :: incorrect_answers)
            (field "correct_answer" string)
            (field "incorrect_answers" (list string))
        )


view : Model -> Html.Html Msg
view model =
    div []
        [ case model.game of
            Loading ->
                text "Loading the questions..."

            Loaded game ->
                div [ class "question" ] [ text game.currentQuestion.question ]

            OnError ->
                text "An unknown error occurred while loading the questions."
        ]


gamePage : Question -> Html msg
gamePage question =
    div []
        [ h2 [ class "question" ] [ text question.question ]
        , ul [ class "answers" ] (List.map displayAnswer question.answers)
        ]


displayAnswer : String -> Html msg
displayAnswer answer =
    li [] [ a [ class "btn btn-primary" ] [ text answer ] ]



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

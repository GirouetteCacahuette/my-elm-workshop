module Step12.GamePage exposing (Question, gamePage, main, questionToDisplay)

import Html exposing (Html, a, div, h2, li, text, ul)
import Html.Attributes exposing (class)
import Utils.Utils exposing (styles, testsIframe)


type alias Question =
    { question : String
    , correctAnswer : String
    , answers : List String
    }


questionToDisplay =
    { question = "What doesn't exist in Elm?"
    , correctAnswer = "Runtime exceptions"
    , answers = [ "Runtime exceptions", "JSON", "Single page applications", "Happy developers" ]
    }


gamePage : Question -> Html msg
gamePage question =
    div []
        [ h2 [ class "question" ] [ text question.question ]
        , ul [ class "answers" ]
            (List.map
                (\answer ->
                    li []
                        [ a [ class "btn btn-primary" ] [ text answer ] ]
                )
                question.answers
            )
        ]



------------------------------------------------------------------------------------------------------
-- Don't modify the code below, it displays the view and the tests and helps with testing your code --
------------------------------------------------------------------------------------------------------


main : Html msg
main =
    div []
        [ styles
        , div [ class "jumbotron" ] [ gamePage questionToDisplay ]
        , testsIframe
        ]

module Step02.ResultPage exposing (main, resultPage)

import Html exposing (Html, a, div, h1, text)
import Html.Attributes exposing (class, href)
import Utils.Utils exposing (styles, testsIframe)


resultPage : Int -> Html msg
resultPage score =
    div [ class "score" ]
        [ h1 [] [ text "Your score: ", text (String.fromInt score), text " / 5" ]
        , a [ class "btn btn-primary", href "#" ] [ text "Replay" ]
        ]



------------------------------------------------------------------------------------------------------------------------
-- You don't need to worry about the code below, it only displays the result of your code and the result of the tests --
------------------------------------------------------------------------------------------------------------------------


main =
    div []
        [ styles
        , div [ class "jumbotron" ] [ resultPage 3 ]
        , testsIframe
        ]

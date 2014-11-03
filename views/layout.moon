html = require "lapis.html"

class extends html.Widget
  content: =>
    html_5 ->
      head ->
        meta charset: 'utf-8'
        title @title or "Kodomo Hometask"
      body ->
        h1 class: "header", "Kodomo Hometask"
        @content_for "inner"


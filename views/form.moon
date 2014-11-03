import Widget from require "lapis.html"

class Welcome extends Widget
  content: =>
    form {
      action: "/send"
      method: "POST"
      enctype: "multipart/form-data"
    }, ->
      input type: "file", name: "uploaded_file"
      input type: "submit"


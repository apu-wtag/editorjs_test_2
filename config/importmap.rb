# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@editorjs/editorjs", to: "@editorjs--editorjs.js" # @2.30.8
pin "@editorjs/header", to: "@editorjs--header.js" # @2.8.8
pin "@editorjs/list", to: "@editorjs--list.js" # @2.0.8
pin "@editorjs/paragraph", to: "@editorjs--paragraph.js" # @2.11.7
pin "@editorjs/code", to: "@editorjs--code.js" # @2.9.3

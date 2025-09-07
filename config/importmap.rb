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
pin "@editorjs/attaches", to: "@editorjs--attaches.js" # @1.3.0
pin "@editorjs/delimiter", to: "@editorjs--delimiter.js" # @1.4.2
pin "@editorjs/embed", to: "@editorjs--embed.js" # @2.7.6
pin "@editorjs/image", to: "@editorjs--image.js" # @2.10.3
pin "@editorjs/quote", to: "@editorjs--quote.js" # @2.7.6
pin "@editorjs/table", to: "@editorjs--table.js" # @2.4.5
pin "@editorjs/marker", to: "@editorjs--marker.js" # @1.4.0
pin "@editorjs/inline-code", to: "@editorjs--inline-code.js" # @1.5.2

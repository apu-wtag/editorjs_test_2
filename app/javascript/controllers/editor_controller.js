import { Controller } from "@hotwired/stimulus";
import EditorJS from "@editorjs/editorjs";
// These are the plugins
// import CodeTool from "@editorjs/code";
// import CustomCodeTool from "./cutstom_code_tool";
import Header from "@editorjs/header";
// import ImageTool from "@editorjs/image";
import List from "@editorjs/list";
import Paragraph from "@editorjs/paragraph";
import ImageTool from "@editorjs/image";
import AttachesTool from "@editorjs/attaches";
import Embed from "@editorjs/embed";
import Quote from "@editorjs/quote";
import Delimiter from "@editorjs/delimiter";
import Table from "@editorjs/table";
import Marker from "@editorjs/marker";
import InlineCode from "@editorjs/inline-code";

// Connects to data-controller="editor"
export default class extends Controller {
  static targets = ["article_content"];

  csrfToken() {
    const metaTag = document.querySelector("meta[name='csrf-token']");
    console.log(metaTag);
    return metaTag ? metaTag.content : "";
  }
  connect() {
    console.log("Hello, Stimulus!", this.element);

    const initialContent = this.getInitialContent();

    this.contentEditor = new EditorJS({
      // Holder is the target element
      holder: this.article_contentTarget,
      data: initialContent,
      placeholder: "Tell your story...",
      tools: {
        header: {
          class: Header,
        },
        list: {
          class: List,
        },
        paragraph: {
          class: Paragraph,
          config: {
            inlineToolbar: true,
          },
        },
        code: {
          class : window.CodeTool,
          config: {
            placeholder: "Enter your code here...",
          },
        },
        image: {
          class: ImageTool,
          config: {
            uploader: {
              uploadByFile: (file) => {
                let formData = new FormData();
                formData.append('file', file);
                return fetch('/articles/upload_image', {
                  method: 'POST',
                  body: formData,
                  headers: {
                    'X-CSRF-Token': this.csrfToken()
                  }
                }).then(response => response.json()).then(data => {
                  if (data.success === 1) {
                    return {
                      success: 1,
                      file: {
                        url: data.file.url,
                        signed_id: data.file.signed_id
                      }
                    };
                  } else {
                    throw new Error('Image upload failed');
                  }
                });
              },
              uploadByUrl: (url) => {
                return fetch('/articles/fetch_image_url', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.csrfToken()
                  },
                  body: JSON.stringify({ url })
                }).then(response => response.json()).then(data => {
                  if (data.success === 1) {
                    return {
                      success: 1,
                      file: {
                        url: data.file.url,
                        signed_id: data.file.signed_id
                      }
                    };
                  } else {
                    throw new Error('Image fetch failed');
                  }
                });
              }
            }
          }
        },
        attaches: {
          class: AttachesTool,
          config: {
            uploader: {
              uploadByFile: (file) => {
                let formData = new FormData();
                formData.append('file', file);
                return fetch('/articles/upload_file', {
                  method: 'POST',
                  body: formData,
                  headers: {
                    'X-CSRF-Token': this.csrfToken()
                  }
                }).then(response => response.json()).then(data => {
                  if (data.success === 1) {
                    return {
                      success: 1,
                      file: data.file,
                      signed_id: data.file.signed_id
                    };
                  } else {
                    throw new Error('File upload failed');
                  }
                });
              }
            }
          }
        },
        embed: {
          class: Embed,
          // config: {
          //   services: {
          //     youtube: true,
          //     twitter: true  // Note: Twitter is now X, but the key remains 'twitter'
          //   }
          // },
          inlineToolbar: true,  // Enables inline tools for embed captions
          toolbox: {
            title: 'Embed',  // Toolbar label
            icon: '<svg width="17" height="15" viewBox="0 0 338 303" xmlns="http://www.w3.org/2000/svg"><path d="M322.9 0H15.1C6.8 0 0 6.8 0 15.1v272.7c0 8.3 6.8 15.1 15.1 15.1h307.8c8.3 0 15.1-6.8 15.1-15.1V15.1c0-8.3-6.8-15.1-15.1-15.1zM196.5 212.3l-83.3 48.1c-3.8 2.2-8.4 2.2-12.2 0-3.8-2.2-6.1-6.1-6.1-10.3V52.9c0-4.2 2.3-8.1 6.1-10.3 3.8-2.2 8.4-2.2 12.2 0l83.3 48.1c3.8 2.2 6.1 6.1 6.1 10.3v149.2c0 4.2-2.3 8.1-6.1 10.3z"/></svg>'  // Icon (video-like symbol)
          }
        },
        quote: {
          class: Quote,
          inlineToolbar: true,
          shortcut: 'CMD+SHIFT+O',
          config: {
            quotePlaceholder: 'Enter a quote... Press SHIFT+ENTER for newline',
            captionPlaceholder: 'Quote\'s author',
          },
        },
        delimiter: {
          class: Delimiter
        },
        table: {
          class: Table,
          inlineToolbar: true, // Allows inline formatting for table content
          config: {
            withHeadings: true // Enables header row toggle in editor
          }
        },
        marker: {
          class: Marker,
          shortcut: 'CMD+SHIFT+M'
        },
        inlineCode: {
          class: InlineCode,
          shortcut: 'CMD+SHIFT+C'
        }
      },
    });

    this.element.addEventListener("submit", this.saveEditorData.bind(this));
    const titleInput = document.getElementById("article_title");
    const topicInput = document.getElementById("article_topic_name");

    // Handle "Enter" from Title -> move to Topic
    if (titleInput && topicInput) {
      titleInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          topicInput.focus(); // Focus the topic input
        }
      });
    }

    // Handle "Enter" from Topic -> move to Editor Content
    if (topicInput && this.contentEditor) {
      topicInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          this.contentEditor.focus(); // Focus the Editor.js instance
        }
      });
    }

  }

  getInitialContent() {
    const hiddenContentField = document.getElementById(
        "article_content_hidden"
    );
    if (hiddenContentField && hiddenContentField.value) {
      return JSON.parse(hiddenContentField.value);
    }
    return {};
  }

  async saveEditorData(event) {
    event.preventDefault();

    const outputData = await this.contentEditor.save();
    const articleForm = this.element;

    const hiddenInput = document.getElementById("article_content_hidden");

    hiddenInput.value = JSON.stringify(outputData);
    articleForm.submit();
  }
}
import { Controller } from "@hotwired/stimulus"

// This controller provides a custom autocomplete dropdown without any external libraries.
export default class extends Controller {
  // We need to track the input field, the results container, and every individual option
  static targets = ["input", "results", "option"]

  connect() {
    // This adds a global "click away" listener. If the user clicks anywhere
    // on the page, we will hide the results dropdown.
    this.boundHideResults = this.hideResults.bind(this)
    document.addEventListener("click", this.boundHideResults)
  }

  disconnect() {
    // This cleans up the listener when the user leaves the page
    document.removeEventListener("click", this.boundHideResults)
  }

  /**
   * This is the core filtering function. It runs every time the user types.
   */
  filter() {
    const query = this.inputTarget.value.toLowerCase()

    // Show the dropdown only if the user has typed something
    this.resultsTarget.classList.toggle("hidden", query.length === 0)

    // Loop through every topic in the list
    this.optionTargets.forEach((el) => {
      const text = el.textContent.toLowerCase()
      const isMatch = text.includes(query)

      // Hide the topic if it doesn't match the search query
      el.classList.toggle("hidden", !isMatch)
    })
  }

  /**
   * This runs when a user clicks a topic from the results list.
   */
  select(event) {
    event.preventDefault()
    // This stops the click from triggering the global "click away" listener
    event.stopPropagation()

    // Get the text from the clicked item
    const selectedText = event.currentTarget.textContent.trim()

    // Put that text into the input field
    this.inputTarget.value = selectedText

    // Hide the results dropdown
    this.hideResults()
  }

  /**
   * A helper function to hide the results dropdown.
   */
  hideResults() {
    if (!this.resultsTarget.classList.contains("hidden")) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  /**
   * This prevents the dropdown from closing when you click *inside* the results list
   * (since that click would otherwise be caught by the global listener).
   */
  preventHide(event) {
    event.stopPropagation()
  }
}
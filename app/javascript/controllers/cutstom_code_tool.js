class CustomCodeTool extends CodeTool {
    constructor(config) {
        super(config);
        this.languages = ["javascript", "css", "python", "ruby"]; // Your permitted languages
    }

    drawView() {
        const wrapper = super.drawView();
        const textarea = wrapper.querySelector("textarea");
        const dropdown = wrapper.querySelector("select");

        // Clear existing options
        dropdown.innerHTML = "";

        // Add permitted languages
        this.languages.forEach((lang) => {
            let option = document.createElement("option");
            option.classList.add(`${this.CSS.dropdown}__option`);
            option.textContent = lang;
            option.value = lang;
            if (this.data.language === lang) {
                option.selected = true;
            }
            dropdown.appendChild(option);
        });

        return wrapper;
    }
}

export default CustomCodeTool;
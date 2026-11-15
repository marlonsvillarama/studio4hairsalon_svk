import { getContext, setContext } from "svelte";

export class User {
    #firstName;
    #lastName;
    #email;
    #phone;
    #returning;

    constructor() {
        this.#firstName = '';
        this.#lastName = '';
        this.#email = '';
        this.#phone = '';
        this.#returning = false;
    }

    get firstName() { return this.#firstName }
    get lastName() { return this.#lastName }
    get email() { return this.#email }
    get phone() { return this.#phone }
    get isReturning() { return this.#returning }
    get data() {
        return {
            firstName: this.#firstName,
            lastName: this.#lastName,
            email: this.#email,
            phone: this.#phone
        }
    }

    updateFirstName(value) { this.#firstName = value }
    updateLastName(value) { this.#lastName = value }
    updateEmail(value) { this.#email = value }
    updatePhone(value) { this.#phone = value }
    updateIsReturning(value) { this.#returning = value }
}


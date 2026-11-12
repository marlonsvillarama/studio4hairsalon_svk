<script>
    import { reveal } from "$lib/reveal";

    let {
        onlogin
    } = $props();
</script>

<div class="booking-login reveal-section from-bottom" use:reveal>
    <h1>Book Now</h1>
    <p>
        Welcome to Studio 4, your premier destination for top-notch hair care and relaxation in the heart of Palmerston North.
    </p>
    <!-- <p>
        We combine modern techniques with a warm and inviting atmosphere to ensure every visit is an enjoyable and luxurious experience.
    </p> -->
    <p>
        Whether you're looking for a fresh haircut, a stunning color transformation, or a rejuvenating treatment, we are here to make you look and feel your best.
    </p>
    <!-- <button type="button" id="book-now">
        Book Now
        <i class="ph ph-arrow-circle-down"></i>
    </button> -->

    <div class="actions">
        <div class="btn-social">
            <img src="/images/icons/google-logo.svg" class="icon-social" alt="Login with Google">
            <span>Login with Google</span>
        </div>
        <div class="btn-social">
            <img src="/images/icons/facebook-logo.svg" class="icon-social" alt="Login with Facebook">
            <span>Login with Facebook</span>
        </div>
        <div class="divider">
            <div class="line"></div>
            <span>or</span>
            <div class="line"></div>
        </div>
        <div class="form email-login">
            <label for="email">Enter your email address</label>
            <input type="text" id="email" name="email" />
            <button type="button" class="btn-action" onclick={onlogin}>
                Login or Register
            </button>
        </div>
    </div>
    
    <!-- <div class="forms">
        <div class="form">
            <label for="first-name">Email</label>
            <span class="lbl-email">marlonsvillarama@gmail.com</span>
        </div>
        <div class="form">
            <label for="first-name">First Name</label>
            <input type="text" id="first-name" name="first-name" />
        </div>
        <div class="form">
            <label for="last-name">Last Name</label>
            <input type="text" id="last-name" name="last-name" />
        </div>
        <div class="form">
            <label for="phone">Phone No.</label>
            <input type="tel" id="phone" name="phone" />
        </div>
        <button type="button" class="btn-action">
            Save my details
        </button>
    </div> -->
</div>

<style>
    .booking-login {
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        padding-top: 8rem;
        background-color: var(--accent-bg-very-light);
        /* border: 1px solid red; */
    }
    @media (min-width: 60rem) {
        .booking-login {
            padding-top: 0;
        }
    }
    /* .booking-login > .header {
        width: max(24rem, 85%);
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 1rem;
    } */
    .booking-login > h1 {
        color: var(--darkest);
        font: 600 clamp(2rem, 5vw, 2rem) var(--font-serif);
    }
    .booking-login > p {
        text-align: center;
        width: min(90%, 42rem);
    }

    .booking-login > .actions {
        margin-top: 1rem;
        width: min(24rem, 90%);
        /* border: 1px solid red; */
    }
    .booking-login > .actions > .btn-social {
        /* width: 20rem; */
        background-color: var(--white);
        border: 1px solid var(--semi-light);
        border-radius: 0.25rem;
        cursor: pointer;
        padding: 0.5rem 1rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        justify-content: center;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out;
        margin-bottom: 0.5rem;
    }
    .booking-login > .actions > .btn-social:hover {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-300);
    }
    .booking-login > .actions > .btn-social > img {
        height: 1.25rem;
    }
    .booking-login > .actions > .btn-social > span {
        /* font: 600 0.875rem var(--font-default); */
        font-weight: 600;
    }
    .booking-login > .actions > .divider {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin: 1rem 0;
    }
    .booking-login > .actions > .divider > .line {
        height: 0.5px;
        border: 1px solid var(--semi-light);
        flex: 1;
    }
    .booking-login > .actions > .form {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        margin-bottom: 1rem;
    }
    .booking-login > .actions > .form.email-login {
        align-items: center;
    }
    .booking-login > .actions > .form > label {
        opacity: 0.7;
    }
    .booking-login > .actions > .form > input[type=text],
    .booking-login > .actions > .form > input[type=tel] {
        background-color: var(--white);
        border: 1px solid var(--semi-light);
        border-radius: 0.25rem;
        padding: 0.375rem 0.75rem;
        margin-bottom: 0.5rem;
    }
    .booking-login > .actions > .form > input[type=text] {
        width: 100%;
    }
    .booking-login > .actions > .form > input[type=tel] {
        width: 12rem;
    }
    .booking-login > .actions > .form > label {
        padding: 0.375rem 0;
        /* margin-bottom: 0.5rem; */
        font-weight: 600;
    }
    .booking-login > .actions .btn-action {
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        cursor: pointer;
        font-weight: 600;
        padding: 0.375rem 2rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out;
    }
    .booking-login > .actions .btn-action:hover {
        background-color: var(--color-accent-500);
    }
</style>
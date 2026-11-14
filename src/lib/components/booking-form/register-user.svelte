<script>
    import { reveal } from "$lib/reveal";

    let {
        firstname = $bindable(''),
        lastname = $bindable(''),
        phone = $bindable(''),
        onsubmit
    } = $props();
</script>

<div class="register-user reveal-section from-bottom" use:reveal>
    <h1>Join Us!</h1>
    <p>
        Welcome to Studio 4, your premier destination for top-notch hair care and relaxation in the heart of Palmerston North.
    </p>
    <!-- <p>
        We combine modern techniques with a warm and inviting atmosphere to ensure every visit is an enjoyable and luxurious experience.
    </p> -->
    <!-- <p>
        Whether you're looking for a fresh haircut, a stunning color transformation, or a rejuvenating treatment, we are here to make you look and feel your best.
    </p> -->
    <!-- <button type="button" id="book-now">
        Book Now
        <i class="ph ph-arrow-circle-down"></i>
    </button> -->

    <div class="form">
        <!-- <div class="btn-social">
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
        </div> -->
        <div class="field">
            <label for="first-name">Email address</label>
            <span class="disabled">your_email@gmail.com</span>
            <!-- <input type="text" id="first-name" name="first-name" /> -->
        </div>
        <div class="field required">
            <label for="first-name">First name</label>
            <input type="text" id="first-name" name="first-name" bind:value={firstname} />
        </div>
        <div class="field required">
            <label for="last-name">Last name</label>
            <input type="text" id="last-name" name="last-name" bind:value={lastname} />
        </div>
        <div class="field">
            <label for="phone">Phone</label>
            <input type="tel" id="phone" name="phone" bind:value={phone} />
        </div>
        <!-- <p class="reminder">
            We will not use 
        </p> -->
        <button type="button" class="btn-action" onclick={onsubmit}>
            Register
        </button>
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
    .register-user {
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
        .register-user {
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
    .register-user > h1 {
        color: var(--darkest);
        font: 600 clamp(2rem, 5vw, 2rem) var(--font-serif);
    }
    .register-user > p {
        text-align: center;
        width: min(90%, 42rem);
    }

    .register-user > .form {
        margin-top: 1rem;
        width: min(24rem, 90%);
    }
    .register-user > .form {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        margin-bottom: 1rem;
        gap: 1.25rem;
        /* border: 1px solid red; */
    }
    .register-user > .form > .field {
        display: flex;
        /* align-items: center; */
        flex-direction: column;
        gap: 0;
        width: 100%;
    }
    .register-user > .form > .field > label {
        font: 300 0.875rem var(--font-default);
        opacity: 0.7;
    }
    .register-user > .form > .field > input[type=text],
    .register-user > .form > .field > input[type=tel] {
        background-color: var(--white);
        border: 1px solid var(--semi-light);
        border-radius: 0.25rem;
        padding: 0.375rem 0.75rem;
        margin-bottom: 0.5rem;
        /* width: 100%; */
    }
    .register-user > .form > .field > input[type=text] {
        width: 100%;
    }
    .register-user > .form > .field > input[type=tel] {
        width: 12rem;
    }
    .register-user > .form > .field.required > label {
        /* padding: 0.375rem 0; */
        /* margin-bottom: 0.5rem; */
        font-weight: 600;
    }
    .register-user > .form .btn-action {
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
    .register-user > .form .btn-action:hover {
        background-color: var(--color-accent-500);
    }
</style>
<script>
    import { reveal } from "$lib/reveal";
    import Logo from "$lib/components/shared/logo.svelte";
</script>

<div class="page-hero">
    <div class="img reveal-section from-left" use:reveal></div>
    <div class="slogan reveal-section from-right" use:reveal>
        <div class="header">
            <Logo />
            <!-- <h1>Book Now</h1> -->
        </div>
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

        <div class="forms">
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
            <div class="form">
                <label for="email">Enter your email address</label>
                <input type="text" id="email" name="email" />
                <button type="button" class="btn-action">
                    Login or Register
                </button>
            </div>
        </div>
        
        <div class="forms">
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
        </div>
    </div>
</div>



<style>
    .page-hero {
        min-height: 100vh;
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
    }
    @media (min-width: 60rem) {
        .page-hero {
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
    }
    .slogan {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        padding-top: 3rem;
        background-color: var(--accent-bg-very-light);
    }
    .slogan > .header {
        width: max(24rem, 85%);
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 1rem;
    }
    .slogan > .header > h1 {
        color: var(--darkest);
        font: 600 clamp(2rem, 5vw, 2rem) var(--font-serif);
    }
    .slogan > p {
        text-align: center;
        width: max(80%, 22rem);
    }
    /* .slogan > p:not(:last-child) {
        margin-bottom: 1rem;
    } */

    #book-now {
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        cursor: pointer;
        font-weight: 600;
        padding: 0.75rem 2rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out;
    }
    #book-now > i {
        font-size: 1.5rem;
    }
    #book-now:hover {
        background-color: var(--color-accent-500);
    }
    .img {
        display: none;
    }
    @media (min-width: 60rem) {
        .img {
            display: block;
            height: 100%;
            background-color: red;
            background-image: url(/images/gallery/book-001.jpg);
            background-size: cover;
            background-position: center;
        }
    }

    .forms {
        margin-top: 1rem;
        width: min(24rem, 90%);
        /* border: 1px solid red; */
    }
    .forms > .btn-social {
        /* width: 20rem; */
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
    .forms > .btn-social:hover {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-300);
    }
    .forms > .btn-social > img {
        height: 1.25rem;
    }
    .forms > .btn-social > span {
        /* font: 600 0.875rem var(--font-default); */
        font-weight: 600;
    }
    .forms > .divider {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin: 1rem 0;
    }
    .forms > .divider > .line {
        height: 0.5px;
        border: 1px solid var(--semi-light);
        flex: 1;
    }
    .forms > .form {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        margin-bottom: 1rem;
    }
    .forms > .form > label {
        opacity: 0.7;
    }
    .forms > .form > input[type=text],
    .forms > .form > input[type=tel] {
        border: 1px solid var(--semi-light);
        border-radius: 0.25rem;
        padding: 0.375rem 0.75rem;
        margin-bottom: 0.5rem;
    }
    .forms > .form > input[type=text] {
        width: 100%;
    }
    .forms > .form > input[type=tel] {
        width: 12rem;
    }
    .forms .lbl-email {
        padding: 0.375rem 0;
        margin-bottom: 0.5rem;
        font-weight: 600;
    }
    .forms .btn-action {
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
    .forms .btn-action:hover {
        background-color: var(--color-accent-500);
    }
</style>
<script>
    import { reveal } from "$lib/reveal";
    // import Header from "$lib/components/shared/header.svelte";
    import Logo from "$lib/components/shared/logo.svelte";
    import BookingLogin from "$lib/components/booking-form/booking-login.svelte";

    let currentPage = $state('email');

    const loginUser = () => {
        currentPage = 'register';
    };
</script>

<!-- <Header /> -->
<!-- <div class="page-hero"> -->
    <!-- <div class="img reveal-section from-left" use:reveal></div> -->
{#if currentPage === 'email'}
    <BookingLogin onlogin={loginUser} />
{:else if currentPage === 'register'}
{/if}
<!-- </div> -->



<style>
    /* .page-hero {
        min-height: 100vh;
        display: flex;
        flex-direction: column;
    }
    @media (min-width: 60rem) {
        .page-hero {
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
    } */
    
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
    /* .img {
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
    } */

    /* .forms {
        margin-top: 1rem;
        width: min(24rem, 90%);
    } */
    /* .forms > .btn-social {
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
    } */
    /* .forms > .btn-social:hover {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-300);
    } */
    /* .forms > .btn-social > img {
        height: 1.25rem;
    } */
    /* .forms > .btn-social > span {
        font-weight: 600;
    } */
    /* .forms > .divider {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin: 1rem 0;
    } */
    /* .forms > .divider > .line {
        height: 0.5px;
        border: 1px solid var(--semi-light);
        flex: 1;
    } */
    /* .forms > .form {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        margin-bottom: 1rem;
    } */
    /* .forms > .form.email-login {
        align-items: center;
    } */
    /* .forms > .form > label {
        opacity: 0.7;
    } */
    /* .forms > .form > input[type=text],
    .forms > .form > input[type=tel] {
        border: 1px solid var(--semi-light);
        border-radius: 0.25rem;
        padding: 0.375rem 0.75rem;
        margin-bottom: 0.5rem;
    } */
    /* .forms > .form > input[type=text] {
        width: 100%;
    } */
    /* .forms > .form > input[type=tel] {
        width: 12rem;
    } */
    /* .forms .lbl-email {
        padding: 0.375rem 0;
        margin-bottom: 0.5rem;
        font-weight: 600;
    } */
    /* .forms .btn-action {
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
    } */
    /* .forms .btn-action:hover {
        background-color: var(--color-accent-500);
    } */
</style>
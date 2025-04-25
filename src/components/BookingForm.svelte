<script>
    import Poster from '$lib/images/poster.jpg';
    import FieldSet from './FieldSet.svelte';
</script>

<section class="wrapper">
    <aside>
        <h4>How to book your appointment</h4>
        <div class="steps">
            <div class="step" data-form-step="1">
                <span>Step 1: Choose what you want</span><br>
                <p>Some text here...</p>
            </div>
            <div class="step active" data-form-step="2">
                <span>Step 2: Share your details</span><br>
                <p>Leave your contact details so we can confirm your appointment.</p>
            </div>
            <div class="step" data-form-step="3">
                <span>Step 3: Confirm your appointment</span><br>
                <p>Some text here...</p>
            </div>
        </div>
    </aside>

    <div class="form" data-form-step="1">
        <FieldSet label="Your Name" />
    </div>

    <div class="form" data-form-step="2">
    </div>

    <div class="form" data-form-step="3">
    </div>
</section>

<style>
    section {
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        gap: 3rem;
    }
    @media (min-width: 64rem) {
        section {
            display: grid;
            grid-template-columns: 40% calc(60% - 4rem);
            gap: 4rem;
        }
    }
    /* .steps {
        border: 1px solid red;
    } */
    aside h4 {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-serif);
        font-size: var(--fs-xl);
        font-weight: 700;
        padding-bottom: 1.5rem;
    }
    .step {
        border: 1px solid transparent;
        padding: 1.5rem 1.75rem;
        margin-bottom: 0.5rem;
    }
    .step.active {
        border: 1px dotted var(--color-accent);
        border-radius: 1rem;
        box-shadow: var(--card-shadow);
    }
    .step > span {
        color: var(--color-accent);
        font-family: var(--font-default);
        font-size: var(--fs-lg);
        font-weight: 300;
        display: inline-block;
        letter-spacing: 0.25px;
        padding-bottom: 0.5rem;
    }
    .step > p {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 200;
        padding-left: 2rem;
        letter-spacing: 0.25px;
    }
    /* section > div {
        align-items: flex-start;
        justify-content: center;
    } */
    /* section:first-child {
        display: none;
    } */
    /* @media (min-width: 64rem) {
        section:first-child {
            display: block;
            justify-content: flex-end;
            width: auto;
            align-items: right;
        }
    } */

    /* img {
        display: none;
    } */
    /* @media (min-width: 64rem) {
        img {
            display: block;
            /!* max-inline-size: 100%; *!/
            width: 100%;
            block-size: auto;
            object-fit: contain;
            object-position: center center;
        }
    } */
    .form {
        /* width: 50%; */
        /* min-width: 20rem; */
        /* margin: 0 auto; */
        border: 0px solid green;
    }
</style>
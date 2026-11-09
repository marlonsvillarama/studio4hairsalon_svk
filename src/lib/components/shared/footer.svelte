<script>
    import Logo from "./logo.svelte";
</script>

<footer>
    <div class="wrapper">
        <section class="logo">
            <Logo />
            <p class="artistry">
                Where <span class="artistry">artistry</span> meets perfection<br />
                &copy; Copyright 2026
            </p>
            <div class="socials">
                <a href="/" title="Studio4 - Facebook">
                    <i class="ph ph-facebook-logo"></i>
                </a>
                <a href="/" title="Studio4 - Instagram">
                    <i class="ph ph-instagram-logo"></i>
                </a>
            </div>
        </section>
        <section>
            <h4>WHERE WE ARE</h4>
            {@render officeDetails("map-pin", "Address",
                `7 George St.<br/>
                Palmerston North`
            )}
            <!-- {@render officeDetails("clock", "Office Hours",
                `Monday - Friday (excluding holidays)<br/>
                9:00 am - 5:00 am`
            )} -->
        </section>
        <section>
            <h4>HOW TO REACH US</h4>
            {@render officeDetails("phone", "Phone",
                `(06) 353-5678<br/>
                (022) 188-5240
                <p>john@studio4hairsalon.co.nz`
            )}
        </section>
        <section>
            <h4>BUSINESS HOURS</h4>
            {@render officeDetails("phone", "Phone",
                `Mondays to Saturdays<br/>
                9:30am to 5:00pm`
            )}
        </section>
    </div>
</footer>

{#snippet officeDetails(icon, title, text)}
<div class="contact-row">
    <div class="details">
        <p>{@html text}</p>
    </div>
</div>
{/snippet}

<style>
    footer {
        background-color: var(--darker);
        border-top: 0.5rem solid var(--color-accent-400);
        padding: 4rem 0 6rem;
    }
    footer > .wrapper {
        /* width: min(90%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 2rem; */
        width: min(90%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 5rem;
    }
    @media (min-width: 40rem) {
        footer > .wrapper {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
        }
    }
    @media (min-width: 60rem) {
        footer > .wrapper {
            grid-template-columns: repeat(4, 1fr);
            /* flex-direction: row; */
            /* width: min(90%, 110rem); */
        }
    }
    footer > .wrapper > * {
        display: flex;
        flex-direction: column;
        /* gap: 0.5rem; */
        color: var(--off-white);
        /* border: 1px solid red; */
    }
    footer > .wrapper > .logo > p {
        color: var(--color-off-white);
        font: 400 clamp(1rem, 8vw, 1rem) var(--font-default);
        letter-spacing: -0.25px;
        line-height: 1.5rem;
        /* line-height: clamp(3.25rem, 8vw, 4.5rem); */
        margin-top: 1rem;
        text-box: trim-both cap alphabetic;
    }
    footer > .wrapper > .logo > p > .artistry {
        color: var(--color-accent-500);
        font-weight: 500;
    }
    /* footer > .wrapper > .logo > p.copy {
        font-size: 0.875rem;
        opacity: 0.7;
    } */
    footer > .wrapper > .logo > .socials {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-top: 1rem;
    }
    footer > .wrapper > .logo > .socials > a {
        color: var(--white);
        font-size: 2rem;
        /* height: 2rem;
        width: 2rem; */
        /* background-color: var(--accent);
        border-radius: 3rem; */
    }
    footer > .wrapper > section > h4 {
        opacity: 0.5;
        font-size: 0.875rem;
    }
    footer > .wrapper > section > .contact-row {
        /* border: 1px solid red; */
        margin-top: 0.5rem;
    }
</style>

<script>
    import Logo from "./logo.svelte";
</script>

<footer>
    <div class="wrapper">
        <section class="logo">
            <Logo />
            <p class="artistry">
                Where <span class="artistry">artistry</span> meets precision<br />
                &copy; Copyright 2026
            </p>
            <!-- Facebook and Instagram icons go here once the real page URLs are known. -->
        </section>
        <section>
            <h2>Where we are</h2>
            <address>
                7 George St.<br />
                Palmerston North
            </address>
        </section>
        <section>
            <h2>How to reach us</h2>
            <p>
                <a href="tel:+6463535678">(06) 353-5678</a><br />
                <a href="tel:+64221885240">(022) 188-5240</a><br />
                <a href="mailto:john@studio4hairsalon.co.nz">john@studio4hairsalon.co.nz</a>
            </p>
        </section>
        <section>
            <h2>Business hours</h2>
            <p>
                Mondays to Saturdays<br />
                9:30am to 5:00pm
            </p>
        </section>
    </div>
</footer>

<style>
    footer {
        background-color: var(--darker);
        border-top: 0.5rem solid var(--color-accent-400);
        padding: 4rem 0 6rem;
    }
    footer > .wrapper {
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
        }
    }
    footer > .wrapper > * {
        display: flex;
        flex-direction: column;
        color: var(--off-white);
    }
    footer > .wrapper > .logo > p {
        color: var(--color-off-white);
        font: 400 clamp(1rem, 8vw, 1rem) var(--font-default);
        letter-spacing: -0.25px;
        line-height: 1.5rem;
        margin-top: 1rem;
        text-box: trim-both cap alphabetic;
    }
    footer > .wrapper > .logo > p > .artistry {
        color: var(--color-accent-500);
        font-weight: 500;
    }
    footer > .wrapper > section > h2 {
        color: var(--color-accent-300);
        font-size: 0.875rem;
        font-weight: 600;
        letter-spacing: 0.06em;
        text-transform: uppercase;
    }
    footer > .wrapper > section > address,
    footer > .wrapper > section > p {
        font-style: normal;
        line-height: 1.6;
        margin-top: 0.5rem;
    }
    footer a {
        text-decoration: underline;
        text-decoration-color: rgba(245, 241, 232, 0.35);
        text-underline-offset: 4px;
    }
    footer a:hover {
        text-decoration-color: var(--color-accent-400);
    }
</style>

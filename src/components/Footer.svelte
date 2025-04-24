<script></script>

<footer>
    <div class="wrapper content">
        <div class="footer-logo">
            <a href="/"><span class="logo">Studio 4</span></a><br/>
            <span>Where artistry meets <span class="accent">precision</span></span><br/>
            <span>&copy; Copyright 2025</span>
        </div>

        <nav>
            <span><a href="/book" class="cta">Book Now</a></span>
            <a href="/services"><span>Browse our services</span></a>
            <a href="/gallery"><span>See our past work</span></a>
            <a href="/reviews"><span>Read our client reviews</span></a>
        </nav>

        <div class="slogan">
            <p>Indulge in the ultimate salon experience.</p>
            <address>
                <div>7 George Street, Palmerston North</div>
                <div class="labeled">
                    <span>Phone:</span>
                    <span>(06) 353-5678</span>
                </div>
                <div class="labeled">
                    <span>Mobile:</span>
                    <span>(022) 188-5240</span>
                </div>
            </address>
        </div>
    </div>
</footer>

<style>
    footer {
        background-color: var(--color-bg-header);
        padding: 4rem 0 6rem;
        font-size: var(--fs-sm);
        font-weight: 200;
        color: white;
    }
    footer > .content {
        border: 0px solid red;
    }
    @media (min-width: 64rem) {
        footer > .content {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 2rem;
        }
    }
    .footer-logo {
        /* display: flex; */
        /* flex-direction: column; */
        /* gap: 2rem; */
        letter-spacing: 0.5px;
    }
    .footer-logo > span {
        font-size: var(--fs-xs);
    }
    
    nav {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    nav a {
        color: white;
        display: inline;
    }
    nav a:not(.cta):hover::after {
        content: '\00AB';
        padding-left: 0.5rem;
    }
    nav a:not(.cta):hover > span {
        padding-bottom: 0.25rem;
        border-bottom: 1px solid var(--color-accent);
    }
    nav a.cta {
        display: inline-block;
        padding: 0.5rem 2.5rem;
        margin-bottom: 1rem;
        background-color: var(--color-bg-btn);
        box-shadow: var(--button-shadow);
        border-radius: 0.25rem;
        font-size: var(--fs-sm);
        font-weight: 400;
        transition: all 100ms ease-in-out;
    }
    nav a.cta:hover {
        background-color: var(--color-bg-btn-hover);
        transform: translateY(-2px);
    }

    .slogan p {
        font-family: var(--font-default);
        font-size: var(--fs-xl);
        font-weight: 100;
        color: var(--color-accent);
        text-align: end;
    }
    address {
        margin-top: 2rem;
        text-align: end;
        font-style: normal;
        font-size: var(--fs-xs);
    }
    address > .labeled > :first-child {
        display: inline-block;
        width: 5rem;
    }
</style>
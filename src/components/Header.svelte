<script>
    let { minimum = false } = $props();
</script>

<header class={[
    { solo: minimum === true }
]}>
    {#if minimum === true }
    <a class="logo" href="/">Studio 4</a>
    {:else}
    <div class="menu full">
        <nav>
            <a href="/services">Services</a>
            <a href="/gallery">Gallery</a>
            <a href="/reviews">Reviews</a>
        </nav>
        <a class="logo" href="/">Studio 4</a>
        <div>
            <!-- <a href="/contact" class="contact">Contact Us</a> -->
            <a href="/book" class="cta">Book Now</a>
        </div>
    </div>
    <div class="menu small">
        <a class="logo" href="/">Studio 4</a>
        <div>
            <!-- <a href="/contact" class="contact">Contact Us</a> -->
            <a href="/book" class="cta">Book Now</a>
        </div>
    </div>
    {/if}
</header>

<style>
    header {
        background-color: var(--color-bg-header);
        /* padding */
        position: relative;
    }
    .menu {
        margin: 0 auto;
        width: 85%;
        /* position: fixed; */
        /* top: 1rem; */
        /* left: 0; */
        /* right: 0; */
        /* height: 50px; */
        background-color: transparent;
        /* padding: 0.75rem 2rem; */
        /* border: 1px solid red; */
        /* display: grid;
        grid-template-columns: 1fr auto 1fr; */
        /* flex-direction: row; */
        /* justify-content: space-between; */
        display: none;
        align-items: center;
        font-size: var(--fs-sm);
    }
    .menu.small {
        width: 92%;
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        /* grid-template-columns: 1fr auto 1fr; */
    }
    @media (min-width: 64rem) {
        .menu.full {
            display: grid;
            grid-template-columns: 1fr auto 1fr;
        }
        .menu.small {
            display: none;
        }
    }
    .solo {
        padding: 0.5rem 0 0;
        position: relative;
        text-align: center;
    }
    .menu > .logo {
        margin-top: 1rem;
    }
    nav {
        /* list-style-type: none; */
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: row;
        gap: 2.5rem;
    }
    /* li {
        display: inline;
        margin-right: 2.5rem;
    } */
    nav a,
    .contact {
        letter-spacing: 0.75px;
        /* color: var(--color-accent); */
        color: white;
        font-weight: 300;
        padding: 0.5rem 0;
        /* border: 1px solid red; */
        border-bottom: 2px solid transparent;
        transition: all 100ms ease-in;
    }
    /* li a:hover, */
    /* .contact:hover */
    nav a:hover {
        color: white;
        border-bottom: 2px solid var(--color-accent);
        transform: translateY(-2px);
    }
    .menu > div:last-child {
        text-align: end;
    }
    .menu .cta {
        padding: 0.5rem 1.75rem;
        background-color: rgba(239, 191, 4, 0.75);
        border-radius: 0.25rem;
        color: white;
        font-size: var(--fs-xs);
        transition: all 100ms ease-in-out;
    }
    .menu .cta:hover {
        background-color: rgba(239, 191, 4, 0.8);
        /* transform: translateY(-1px); */
        box-shadow: rgba(255, 255, 255, 0.5) 0px 0 4px;
    }
    @media (min-width: 64rem) {
        .menu .cta {
            font-size: var(--fs-sm);
            padding: 0.75rem 2.5rem;
            margin-left: 2rem;
        }
    }
</style>
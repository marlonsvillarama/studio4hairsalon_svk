<script>
    import Logo from "./logo.svelte";
    import Nav from "./nav.svelte";

    let scrollY = $state(0);
</script>

<svelte:window bind:scrollY />

<header class:scrolled={scrollY > 50}>
    <div class="container">
        <Logo />
        <Nav />
    </div>
</header>

<style>
    header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: 1000;
        transition: background-color 300ms ease;
    }
    :global(header.scrolled) {
        /* background-color: var(--darkest); */
        background-color: var(--darkest);
    }
    header > .container {
        /* border: 1px solid red; */
        margin: 0 auto;
        width: 90%;
        max-width: 110rem;
        padding: 1rem 0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        transition: padding 300ms ease;
    }
    @media (min-width: 40rem) {
        header > .container {
            padding: 2rem 0;
        }
    }
    :global(header.scrolled > .container) {
        padding: 1rem 0;
    }
</style>

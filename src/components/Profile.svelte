<script>
    import Full from '$lib/images/john.jpg';
    // import InAction from '$lib/images/in-action.jpg?enhanced';
</script>

<section class="wrapper">
    <div class="pics">
        <img src={Full} alt="John Fernandez">
        <!-- <enhanced:img src={InAction} alt="John Fernandez in action"> -->
    </div>
    <div class="profile">
        <p>Led by <span class="emp accent">John Fernandez</span>, a seasoned professional with over 20 years of international experience, we bring world-class expertise and creativity to every client.</p>
        <p>John’s journey spans the vibrant salons of Dubai, the dynamic multi-franchise networks of the Philippines, and the innovative hair industry of New Zealand.</p>
        <p>This extensive background combines diverse techniques, global trends, and a passion for excellence to ensure you receive a look tailored specifically to your unique style.</p>
        
        <a href="/book" class="btn cta">BOOK NOW</a>
    </div>
</section>

<style>
    section {
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        /* grid-template-columns: calc(60% - 3rem) 40%; */
        align-items: center;
        justify-content: center;
        gap: 4rem;
        clear: both;
    }
    @media (min-width: 64rem) {
        section {
            /* display: flex;
            flex-direction: row; */
            display: grid;
            grid-template-columns: calc(50% - 4rem) 50%;
            align-items: center;
            justify-content: center;
        }
    }
    section > * {
        border: 0px solid red;
    }
    /* .pics {
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    @media (min-width: 40rem) {
        .pics {
            flex-direction: row;
        }
    } */
    .pics {
        width: 80%;
        /* max-width: 80%; */
        margin: 0 auto;
        box-shadow: var(--box-shadow);
    }
    .pics > img {
        width: 100%;
        height: auto;
    }
    @media (min-width: 40rem) {
        .pics {
            width: 80%;
            /* max-width: 80%; */
            margin: 0 auto;
        }
    }
    /* .profile {
        border: 1px solid red;
    } */
    .profile p {
        line-height: 2rem;
        margin-bottom: 2.5rem;
        font-size: var(--fs-sm);
        font-weight: 200;
        letter-spacing: 0.5px;
    }
    @media (min-width: 64rem) {
        .profile p {
            font-size: var(--fs-sm);
        }
    }
    
    .cta {
        padding: 0.75rem 2.5rem;
        background-color: var(--color-bg-btn);
        /* border: 1px solid red; */
        border-radius: 0.25rem;
        color: white;
        font-size: var(--fs-md);
        /* margin-left: 2rem; */
        transition: all 100ms ease-in-out;
        box-shadow: var(--button-shadow);
        display: block;
        text-align: center;
    }
    /* @media (min-width: 64px) {
        .cta {
            display: inline-block;
        }
    } */
    .cta:hover {
        background-color: var(--color-bg-btn-hover);
        transform: translateY(-2px);
        /* box-shadow: rgba(255, 255, 255, 0.5) 0px 0 4px; */
    }
</style>
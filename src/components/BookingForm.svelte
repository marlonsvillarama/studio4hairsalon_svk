<script>
    import Poster from '$lib/images/poster.jpg';
</script>

<section class="wrapper">
    <div class="form"></div>
    <img src={Poster} alt="">
</section>

<style>
    section {
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        border: 1px solid red;
        display: flex;
        flex-direction: column;
        gap: 3rem;
    }
    @media (min-width: 64rem) {
        section {
            display: grid;
            grid-template-columns: calc(65% - 3rem) 35%;
            gap: 3rem;
        }
    }
    section > div {
        align-items: flex-start;
        justify-content: center;
    }
    section:first-child {
        display: none;
    }
    @media (min-width: 64rem) {
        section:first-child {
            display: block;
            justify-content: flex-end;
            width: auto;
            align-items: right;
        }
    }

    img {
        display: none;
    }
    @media (min-width: 64rem) {
        img {
            display: block;
            /* max-inline-size: 100%; */
            width: 100%;
            block-size: auto;
            object-fit: contain;
            object-position: center center;
        }
    }
    .form {
        /* width: 50%; */
        /* min-width: 20rem; */
        /* margin: 0 auto; */
        border: 1px solid green;
    }
</style>
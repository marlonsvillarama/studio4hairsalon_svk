<script></script>

<div class="container">
    <div class="img" role="img"></div>
    <div class="headline">
        <!-- <h1>Studio4</h1> -->
        <span>Where artistry meets <span class="accent">precision</span></span>
    </div>
</div>

<style>
    .container {
        position: relative;
        color: white;
        padding-bottom: 3rem;
    }
    .img {
        /* background-image: url("/images/hero.jpg"); */
        /* background-image: url("/images/H-23.jpg"); */
        height: 100vh;
        max-height: 100vh;
        background-size: cover;
        background-position: center;
        width: 100%;
        display: block;
    }
    .headline {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        text-align: center;
        width: 100%;
        /* width: 80%; */
        padding: 2rem 0;
        background: linear-gradient(rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0.1));
        /* border: 1px solid green; */
        /* box-shadow: rgba(255, 255, 255, 0.8) 0px 5px 15px; */
    }
    .headline > span {
        font-weight: 100;
        font-size: var(--fs-3xl);
        line-height: 4.5rem;
        display: block;
        width: 85%;
        margin: 0 auto;
        /* color: var(--color-accent); */
        letter-spacing: 0.5px;
        /* padding: 0 3rem; */
        /* text-shadow: rgba(255, 255, 255, 0.8) 0px 5px 15px; */
    }
    @media (min-width: 64rem) {
        .headline > span {
            font-size: var(--fs-4xl);
            line-height: 5rem;
            /* width: 85%; */
        }
    }
</style>
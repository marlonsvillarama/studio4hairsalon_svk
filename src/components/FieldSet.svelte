<script>
    import Dropdown from "./Dropdown.svelte";
    let { label, help = '' } = $props();
</script>

<div class="fieldset">
    <h4 class="label">{label}</h4>
    {#if help}
        <p class="help">{help}</p>
    {/if}
    <Dropdown id="test_dd" />
    <span>test</span>
</div>

<style>
    .fieldset {
        min-width: 20rem;
        width: 100%;
        /* border: 1px solid red; */
    }
    h4 {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-md);
        font-weight: 400;
    }
</style>
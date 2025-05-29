<script>
    import '../../css/app.css';
    import Header from '../../components/Header.svelte';

    let { children } = $props();
</script>

<Header minimum={true} />

{@render children()}

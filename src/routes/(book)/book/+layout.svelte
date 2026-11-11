<script>
	import '../../layout.css';
	import favicon from '$lib/assets/favicon.svg';
	// import Header from '$lib/components/shared/header.svelte';
	import Footer from '$lib/components/shared/footer.svelte';

	let { children } = $props();
</script>

{@render children?.()}
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
	const env = loadEnv(mode, process.cwd(), '');

	// Parse allowed hosts from environment variable
	const envAllowedHosts = env.VITE_ALLOWED_HOSTS
		? env.VITE_ALLOWED_HOSTS.split(',').map(host => host.trim())
		: [];

	// Default allowed hosts
	const defaultAllowedHosts = [
		'localhost',
		'127.0.0.1',
	];

	// Combine default and environment-specified hosts
	const allowedHosts = [...defaultAllowedHosts, ...envAllowedHosts];

	return {
		plugins: [sveltekit()],
		server: {
			host: true, // Allow external connections
			allowedHosts,
			fs: {
				allow: ['..'] // Allow serving files from parent directories
			}
		}
	};
});

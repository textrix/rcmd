<script lang="ts">
	import { onMount } from 'svelte';

	let currentTime = new Date().toLocaleString();
	let status = 'Initializing...';

	onMount(() => {
		// Update time every second
		const timeInterval = setInterval(() => {
			currentTime = new Date().toLocaleString();
		}, 1000);

		// Simulate startup sequence
		setTimeout(() => {
			status = 'Docker environment ready';
		}, 1000);

		return () => {
			clearInterval(timeInterval);
		};
	});
</script>

<svelte:head>
	<title>RCMD - Rclone Commander</title>
	<meta name="description" content="A modern web-based and desktop GUI application for managing Rclone cloud storage operations" />
</svelte:head>

<main class="container">
	<header class="header">
		<div class="logo">
			<h1>RCMD</h1>
			<span class="subtitle">Rclone Commander</span>
		</div>
		<div class="status">
			<span class="status-indicator {status.includes('ready') ? 'ready' : 'loading'}"></span>
			<span class="status-text">{status}</span>
		</div>
	</header>

	<section class="hero">
		<h2>Cloud Storage Orchestration Platform</h2>
		<p>Manage 101+ cloud storage providers through a unified interface</p>

		<div class="features">
			<div class="feature">
				<div class="feature-icon">☁️</div>
				<h3>Multi-Cloud</h3>
				<p>Support for all major cloud storage providers via Rclone</p>
			</div>

			<div class="feature">
				<div class="feature-icon">📁</div>
				<h3>File Management</h3>
				<p>Intuitive file browser with drag-and-drop support</p>
			</div>

			<div class="feature">
				<div class="feature-icon">🔄</div>
				<h3>Transfer Queue</h3>
				<p>Real-time transfer monitoring and management</p>
			</div>
		</div>
	</section>

	<section class="info">
		<div class="stats">
			<div class="stat">
				<div class="stat-number">101+</div>
				<div class="stat-label">Cloud Providers</div>
			</div>
			<div class="stat">
				<div class="stat-number">~500TB</div>
				<div class="stat-label">Data Capacity</div>
			</div>
			<div class="stat">
				<div class="stat-number">100%</div>
				<div class="stat-label">Infrastructure Ready</div>
			</div>
		</div>

		<div class="system-info">
			<h3>System Status</h3>
			<div class="info-grid">
				<div class="info-item">
					<span class="label">Environment:</span>
					<span class="value">Development</span>
				</div>
				<div class="info-item">
					<span class="label">Database:</span>
					<span class="value">SQLite (auto-detected)</span>
				</div>
				<div class="info-item">
					<span class="label">Platform:</span>
					<span class="value">Docker + SvelteKit</span>
				</div>
				<div class="info-item">
					<span class="label">Current Time:</span>
					<span class="value">{currentTime}</span>
				</div>
			</div>
		</div>
	</section>

	<footer class="footer">
		<div class="links">
			<a href="/docs" class="link">Documentation</a>
			<a href="/api" class="link">API</a>
			<a href="/status" class="link">Status</a>
		</div>
		<p class="version">
			RCMD v0.0.1 •
			<a href="https://rclone.org" target="_blank" rel="noopener">Powered by Rclone</a>
		</p>
	</footer>
</main>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		min-height: 100vh;
		color: #333;
	}

	.container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
		min-height: 100vh;
		display: flex;
		flex-direction: column;
	}

	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 3rem;
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		padding: 1.5rem 2rem;
		border-radius: 15px;
		border: 1px solid rgba(255, 255, 255, 0.2);
	}

	.logo h1 {
		margin: 0;
		font-size: 2.5rem;
		font-weight: 700;
		color: white;
		text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
	}

	.subtitle {
		color: rgba(255, 255, 255, 0.8);
		font-size: 0.9rem;
		font-weight: 500;
	}

	.status {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		color: white;
	}

	.status-indicator {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: #ffa500;
		animation: pulse 2s infinite;
	}

	.status-indicator.ready {
		background: #4ade80;
		animation: none;
	}

	.status-indicator.loading {
		animation: pulse 1.5s infinite;
	}

	@keyframes pulse {
		0%, 100% { opacity: 1; }
		50% { opacity: 0.5; }
	}

	.hero {
		text-align: center;
		margin-bottom: 4rem;
		color: white;
	}

	.hero h2 {
		font-size: 3rem;
		margin-bottom: 1rem;
		font-weight: 600;
		text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
	}

	.hero p {
		font-size: 1.2rem;
		margin-bottom: 3rem;
		opacity: 0.9;
	}

	.features {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 2rem;
		margin-top: 3rem;
	}

	.feature {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		padding: 2rem;
		border-radius: 15px;
		border: 1px solid rgba(255, 255, 255, 0.2);
		text-align: center;
		transition: transform 0.3s ease;
	}

	.feature:hover {
		transform: translateY(-5px);
	}

	.feature-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.feature h3 {
		margin: 0 0 1rem 0;
		font-size: 1.5rem;
	}

	.feature p {
		margin: 0;
		opacity: 0.9;
		line-height: 1.6;
	}

	.info {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2rem;
		margin-bottom: 3rem;
	}

	.stats {
		display: flex;
		gap: 1rem;
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		padding: 2rem;
		border-radius: 15px;
		border: 1px solid rgba(255, 255, 255, 0.2);
	}

	.stat {
		flex: 1;
		text-align: center;
		color: white;
	}

	.stat-number {
		font-size: 2.5rem;
		font-weight: 700;
		margin-bottom: 0.5rem;
	}

	.stat-label {
		font-size: 0.9rem;
		opacity: 0.8;
	}

	.system-info {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		padding: 2rem;
		border-radius: 15px;
		border: 1px solid rgba(255, 255, 255, 0.2);
		color: white;
	}

	.system-info h3 {
		margin: 0 0 1.5rem 0;
		font-size: 1.3rem;
	}

	.info-grid {
		display: grid;
		gap: 0.8rem;
	}

	.info-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0.5rem 0;
		border-bottom: 1px solid rgba(255, 255, 255, 0.1);
	}

	.info-item:last-child {
		border-bottom: none;
	}

	.label {
		opacity: 0.8;
	}

	.value {
		font-weight: 500;
	}

	.footer {
		margin-top: auto;
		text-align: center;
		color: white;
	}

	.links {
		display: flex;
		justify-content: center;
		gap: 2rem;
		margin-bottom: 1rem;
	}

	.link {
		color: white;
		text-decoration: none;
		padding: 0.5rem 1rem;
		border-radius: 8px;
		background: rgba(255, 255, 255, 0.1);
		transition: background 0.3s ease;
	}

	.link:hover {
		background: rgba(255, 255, 255, 0.2);
	}

	.version {
		opacity: 0.7;
		font-size: 0.9rem;
		margin: 0;
	}

	.version a {
		color: inherit;
	}

	@media (max-width: 768px) {
		.container {
			padding: 1rem;
		}

		.header {
			flex-direction: column;
			gap: 1rem;
			text-align: center;
		}

		.hero h2 {
			font-size: 2rem;
		}

		.info {
			grid-template-columns: 1fr;
		}

		.stats {
			flex-direction: column;
			gap: 1.5rem;
		}

		.links {
			flex-direction: column;
			gap: 1rem;
		}
	}
</style>
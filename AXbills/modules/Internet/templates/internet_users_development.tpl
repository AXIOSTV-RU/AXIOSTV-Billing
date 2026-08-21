<style>
	tfoot > tr > th:nth-child(2),
	tr > td:not([rowspan]):not([colspan]):first-child,
	tr.text-right > td:first-child[rowspan] ~ td:nth-child(2) {
		position: sticky;
		left: 40px;
		background: silver;
	}

	td.skip,
	tfoot > tr > th:first-child,
	tbody > tr:first-child > td:first-child {
		position: sticky !important;
		left: 0 !important;
		background: silver;
	}

	table {
		border-collapse: separate;
		border-spacing: 0;
	}

	.table-responsive {
		display: block;
		max-height: 80vh;
	}

	tr.bg-inherit:first-child {
		position: sticky !important;
		top: 0 !important;
		z-index: 1;
		background: silver !important;
	}

	tr.bg-inherit:nth-child(2) {
		position: sticky !important;
		top: 36px !important;
		background: silver !important;
	}

	tr.bg-inherit:nth-child(3) {
		position: sticky !important;
		top: 70px !important;
		background: silver !important;
	}

	tr.bg-inherit:nth-child(4) {
		position: sticky !important;
		top: 100px !important;
		background: silver !important;
	}
</style>
#!/usr/bin/perl -w

use ProductOpener::PerlStandards;

use Test2::V0;
use ProductOpener::APITest qw/create_user edit_product execute_api_tests new_client wait_application_ready/;
use ProductOpener::Test qw/remove_all_products remove_all_users/;
use ProductOpener::TestDefaults qw/%default_user_form %empty_product_form/;

use File::Basename "dirname";

use Storable qw(dclone);

wait_application_ready();

remove_all_users();

remove_all_products();

# First user

my $ua = new_client();
my %create_user_args = (%default_user_form, (email => 'alice@gmail.com', userid => "alice"));
create_user($ua, \%create_user_args);

# Second user

my $ua2 = new_client();
my %create_user_args2 = (%default_user_form, (email => 'bob@gmail.com', userid => "bob"));
create_user($ua2, \%create_user_args2);

# Create some products to test facets

my @products = (
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000001',
			product_name => "Carrots - Organic - France - brand1, brand2",
			categories => "en:carrots",
			labels => "en:organic",
			origins => "en:france",
			brands => 'brand1, brand2',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000002',
			product_name => "Carrots - Fair trade, Organic - France - brand1",
			categories => "en:carrots",
			labels => "en:organic, en:fair-trade",
			origins => "en:france",
			brands => 'brand1',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000003',
			product_name => "Carrots - No label - Belgium - brand2",
			categories => "en:carrots",
			origins => "en:belgium",
			brands => 'brand2',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000004',
			product_name => "Carrots - Fair trade - Italy - brand1, brand2",
			categories => "en:carrots",
			labels => "en:fair-trade",
			origins => "en:italy",
			brands => 'brand1, brand2',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000005',
			product_name => "Bananas - Organic - France - brand2",
			categories => "en:bananas",
			labels => "en:organic",
			origins => "en:france",
			brands => 'brand2',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000006',
			product_name => "Bananas - Organic - Martinique - brand1",
			categories => "en:bananas",
			labels => "en:organic",
			origins => "en:martinique",
			brands => 'brand1',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000007',
			product_name => "Oranges - Organic - Spain - brand1, brand2, brand3",
			categories => "en:oranges",
			labels => "en:organic",
			origins => "en:spain",
			brands => 'brand1, brand2, brand3',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000008',
			product_name => "Oranges - Fair trade - Italy - brand3",
			categories => "en:oranges",
			labels => "en:fair-trade",
			origins => "en:italy",
			brands => 'brand3',
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000009',
			product_name => "Apples - Organic - France",
			categories => "en:apples",
			labels => "en:organic",
			origins => "en:france",
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000010',
			product_name => "Apples - Organic, Fair trade - France",
			categories => "en:apples",
			labels => "en:organic,en:fair-trade",
			origins => "en:france",
			emb_codes =>
				"FR 85.222.003 CE", # EU traceability code to check we normalize and query the code correctly (CE -> EC)
			countries => "France",
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000011',
			product_name => "Apples - Organic - France, Belgium, Canada",
			categories => "en:apples,en:vitamins",
			labels => "en:organic",
			origins => "en:france,en:belgium,en:canada",
		),
	},
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000012',
			product_name => "Chocolate - Organic, Fair trade - Martinique",
			categories => "en:chocolate",
			labels => "en:organic,en:fair-trade",
			origins => "en:martinique",
			lc => "en",
			ingredients_text_en => "Cocoa, sugar, vanilla, vitamiun C",
		),
	},
	# German product with accents in labels
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000013',
			product_name => "Chocolate - Organic, Café Label - Martinique",
			categories => "en:chocolate",
			labels => "en:organic,en:fair-trade,Café Label",
			lang => "de",
			lc => "de",
		),
	},
);

foreach my $product_ref (@products) {
	edit_product($ua, $product_ref);
}

# Create another product with a different contributor

edit_product(
	$ua2,
	{
		%{dclone(\%empty_product_form)},
		(
			code => '200000000101',
			product_name => "Yogurt - Organic, Fair trade - Martinique",
			categories => "en:yogurt",
			labels => "en:organic,en:fair-trade",
			origins => "en:france",
		),
	}
);

# Note: expected results are stored in json files, see execute_api_tests
# We use the API with .json to test facets, in order to easily get the products that are returned
my $tests_ref = [
	{
		test_case => 'brand_brand1',
		method => 'GET',
		path => 'facets/brands/brand1.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'brand_-brand1',
		method => 'GET',
		path => 'facets/brands/-brand1.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'brand_brand2_brand_-brand1',
		method => 'GET',
		path => 'facets/brands/brand2/brands/-brand1.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_apples',
		method => 'GET',
		path => 'facets/categories/apples.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_-apples',
		method => 'GET',
		path => 'facets/categories/-apples.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_apples_label_organic',
		method => 'GET',
		path => 'facets/categories/apples/labels/organic.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_-apples_label_organic',
		method => 'GET',
		path => 'facets/categories/-apples/labels/organic.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_-apples_label_-organic',
		method => 'GET',
		path => 'facets/categories/-apples/labels/-organic.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'label_fair-trade_label_-organic',
		method => 'GET',
		path => 'facets/labels/fair-trade/labels/-organic.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# test with 3 facets
	{
		test_case => 'category_bananas_label_organic_brand_brand1',
		method => 'GET',
		path => 'facets/categories/bananas/labels/organic/brands/brand1.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'category_bananas_label_organic_brand_-brand1',
		method => 'GET',
		path => 'facets/categories/bananas/labels/organic/brands/-brand1.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# Special unknown value, should match unexisting or empty tags array
	{
		test_case => 'brand_unknown',
		method => 'GET',
		path => 'facets/brands/unknown.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'brand_-unknown',
		method => 'GET',
		path => 'facets/brands/-unknown.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# EU packager code
	{
		test_case => 'packager-code_fr-85-222-003-ce',
		method => 'GET',
		path => 'facets/packager-codes/fr-85-222-003-ce.json?fields=product_name,emb_codes_tags',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'packager-code_fr-85-222-003-ec',    # not normalized code (ec instead of ce)
		method => 'GET',
		path => 'facets/packager-codes/fr-85-222-003-ce.json?fields=product_name,emb_codes_tags',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# contributor facet
	{
		test_case => 'contributor-alice',
		method => 'GET',
		path => 'facets/contributors/alice.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	{
		test_case => 'contributor-bob',
		method => 'GET',
		path => 'facets/contributors/bob.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# contributor + another facet
	{
		test_case => 'contributor-alice-label_organic',
		method => 'GET',
		path => 'facets/contributors/alice/labels/organic.json?fields=product_name',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# accented facet value in German
	{
		test_case => 'de-accented-cafe-label',
		method => 'GET',
		subdomain => 'world-de',
		path => 'facets/labels/café-label.json?fields=product_name,labels_tags',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# facet name that is the same as a facet type
	# https://github.com/openfoodfacts/openfoodfacts-server/issues/9708
	{
		test_case => 'category-vitamins',
		method => 'GET',
		path => 'facets/categories/vitamins.json?fields=product_name,labels_tags',
		expected_status_code => 200,
		sort_products_by => 'product_name',
	},
	# test some redirects
	{
		test_case => 'redirect-facets-singulars',
		method => 'GET',
		path => '/category/vitamins',
		expected_status_code => 301,
		headers => {
			Location => '/facets/categories/vitamins',
		},
		expected_type => 'html',
	},
	{
		test_case => 'redirect-facets-search-with-json',
		method => 'GET',
		path => '/categories/vitamins.json',
		expected_status_code => 301,
		headers => {
			Location => '/facets/categories/vitamins.json',
		},
		expected_type => 'html',    # the redirect itself is html
	},
	{
		test_case => 'redirect-facets-search-with-json-and-query-parameter',
		method => 'GET',
		path => '/categories/vitamins.json?no_cache=1',
		expected_status_code => 301,
		headers => {
			Location => '/facets/categories/vitamins.json?no_cache=1',
		},
		expected_type => 'html',    # the redirect itself is html
	},
	{
		test_case => 'redirect-facets-search-with-json-query-parameter',
		method => 'GET',
		path => '/categories/vitamins?json=1',
		expected_status_code => 301,
		headers => {
			Location => '/facets/categories/vitamins?json=1',
		},
		expected_type => 'html',    # the redirect itself is html
	},
	{
		test_case => 'redirect-facets-with-multiple-query-parameters',
		method => 'GET',
		path => '/ingredients?filter=bon&status=unknown',
		expected_status_code => 301,
		headers => {
			Location => '/facets/ingredients?filter=bon&status=unknown',
		},
		expected_type => 'html',    # the redirect itself is html
	},
	{
		test_case => 'redirect-facets-agg-with-json',
		method => 'GET',
		path => '/categories.json',
		expected_status_code => 301,
		headers => {
			Location => '/facets/categories.json',
		},
		expected_type => 'html',    # the redirect itself is html
	},
];

# note: we need to execute the tests with bob, because we need authentication
# to see data quality panels
execute_api_tests(__FILE__, $tests_ref, $ua);

done_testing();

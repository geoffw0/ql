
void use(int i);

int maybeInitialize1(int *v)
{
	static int resources = 100;

	if (resources == 0)
	{
		return 0; // FAIL
	}

	*v = resources--;
	return 1; // SUCCESS
}

void test1()
{
	int a, b, c, d, e, f;
	int result1, result2;

	maybeInitialize1(&a); // BAD (initialization not checked)
	use(a);
	
	if (maybeInitialize1(&b) == 1) // GOOD
	{
		use(b);
	}
	
	if (maybeInitialize1(&c) == 0) // BAD (initialization check is wrong) [NOT DETECTED]
	{
		use(c);
	}

	result1 = maybeInitialize1(&d); // BAD (initialization stored but not checked) [NOT DETECTED]
	use(d);

	result2 = maybeInitialize1(&e); // GOOD
	if (result2 == 1)
	{
		use(e);
	}

	if (maybeInitialize1(&f) == 0) // GOOD
	{
		return;
	}
	use(f);
}

bool maybeInitialize2(int *v)
{
	static int resources = 100;

	if (resources > 0)
	{
		*v = resources--;
		return true; // SUCCESS
	}

	return false; // FAIL
}

void test2()
{
	int a, b;

	maybeInitialize2(&a); // BAD (initialization not checked)
	use(a);
	
	if (maybeInitialize2(&b)) // GOOD
	{
		use(b);
	}
}

int alwaysInitialize(int *v)
{
	static int resources = 0;

	*v = resources++;
	return 1; // SUCCESS
}

void test3()
{
	int a, b;

	alwaysInitialize(&a); // GOOD (initialization never fails)
	use(a);
	
	if (alwaysInitialize(&b) == 1) // GOOD
	{
		use(b);
	}
}

bool someCondition(int i);

bool alwaysInitialize2(int *v)
{
	for (int i = 0; i < 10; i++)
	{
		*v = i;

		if (someCondition(i)) return true; // SUCCESS
	}

	// (not that *v has been initialized here)
	return false; // FAIL
}

void test4()
{
	int a, b;

	alwaysInitialize2(&a); // GOOD (initialization never fails) [FALSE POSITIVE]
	use(a);

	if (alwaysInitialize2(&b) == 1) // GOOD
	{
		use(b);
	}
}

int someNumber();

bool maybeInitialize3(int *v)
{
	for (int i = 0; i < someNumber(); i++)
	{
		*v = i;

		if (someCondition(i)) return true; // SUCCESS
	}

	// (not that *v may not have been initialized here)
	return false; // FAIL
}

void test5()
{
	int a, b;

	maybeInitialize3(&a); // BAD (initialization not checked)
	use(a);

	if (maybeInitialize3(&b) == 1) // GOOD
	{
		use(b);
	}
}

bool initializeIfNonNull(int *p, int *from)
{
	if (from == 0) return false; // FAIL

	*p = *from;
	return true; // SUCCESS
}

bool initializeIfNull(int *p, int *override)
{
	if (override == 0)
	{
		*p = 10;
		return true; // SUCCESS
	} else {
		return false; // FAIL
	}
}

void test6()
{
	int a, b, c, d, e;

	a = 10;
	initializeIfNonNull(&b, &a); // GOOD (initialization succeeds)
	use(b);

	initializeIfNonNull(&c, 0); // BAD (initialization fails)
	use(c);

	initializeIfNull(&d, &a); // BAD (initialization fails)
	use(d);

	initializeIfNull(&e, 0); // GOOD (initialization succeeds)
	use(e);
}

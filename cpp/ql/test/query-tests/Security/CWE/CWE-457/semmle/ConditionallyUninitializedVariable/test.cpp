
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
	int a, b, c, d, e, f, g, h;
	int result1, result2, result3;

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

	maybeInitialize1(&g); // GOOD (never used)

	result3 = maybeInitialize1(&h); // BAD (initialization check is too late)
	use(h);
	if (result3 == 0) return;
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

bool alwaysInitialize3(int *v)
{
	if (*v != 0)
	{
		*v = 0;
		return true; // SUCCESS
	}

	return false; // FAIL (but `v` is known to be NULL in this case anyway)
}


bool maybeInitialize4(int *v)
{
	if (v != 0)
	{
		*v = 0;
		return true; // SUCCESS
	}

	return false; // FAIL
}

void test7(int *c)
{
	int a, b;

	alwaysInitialize3(&a); // GOOD (initialization failure is safe)
	use(a);

	maybeInitialize4(&b); // GOOD (initialization this way never fails)
	use(b);

	maybeInitialize4(c); // GOOD (initialization fails if there's nothing to initialize)
	if (c != 0)
	{
		use(*c);
	}
}

bool alwaysInitialize4(int *v)
{
	int *v2;

	v2 = v;
	*v2 = 1;
	if (someCondition(1))
	{
		return true; // SUCCESS
	}

	return false; // FAIL
}

bool maybeInitialize5(int *v)
{
	int *v2;

	v2 = v;
	if (someCondition(1))
	{
		*v2 = 1;
		return true; // SUCCESS
	}

	return false; // FAIL
}

void test8()
{
	int a, b;

	alwaysInitialize4(&a); // GOOD (initialization never fails)
	use(a);

	maybeInitialize5(&b); // BAD (initialization may fail) [NOT DETECTED]
	use(b);
}

bool alwaysInitializeFirst(int *a, int *b)
{
	*a = 1;
	if (someCondition(1))
	{
		*b = 1;
	}

	return true; // SUCCESS
}

void test9()
{
	int a, b;

	alwaysInitializeFirst(&a, &b); // BAD (`b` isn't always initialized)
	use(a);
	use(b);
}

int maybeInitializeBoth(int *a, int *b)
{
	int i;

	i = someNumber();
	if (i == 1)
	{
		if (*a)
		{
			*a = 1;
		}
		if (*b)
		{
			*b = 2;
		}
	}

	return i;
}

void test10()
{
	int a, b;

	maybeInitializeBoth(&a, &b); // BAD (x2, may not be initialized)
	if (a < 10)
	{
		// ...
	}	
	if (b == 20)
	{
		// ...
	}
}

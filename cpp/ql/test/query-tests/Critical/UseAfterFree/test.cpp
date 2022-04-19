// Semmle test cases for UseAfterFree.ql (CWE-416).

// library types, functions etc
#define NULL (0)
typedef unsigned long size_t;
void *malloc(size_t size);
void free(void *ptr);

void useExternal(char* data);

void use(char* data)
{
	if (data)
		useExternal(data);
}

[[noreturn]]
void noReturn();

void myMalloc(char** data)
{
	*data = (char *)malloc(100*sizeof(char));
}

void myMalloc2(char* & data)
{
	data = (char*) malloc(100*sizeof(char));
}

void test1()
{
	char* data;
	data = (char *)malloc(100*sizeof(char));
	use(data); // GOOD
	free(data);
	use(data); // BAD
}

void test2()
{
	char* data;
	data = (char *)malloc(100*sizeof(char));
	free(data);
	myMalloc(&data);
	use(data); // GOOD
	free(data);
	myMalloc2(data);
	use(data); // GOOD
}

void test3()
{
	char* data;
	data = (char *)malloc(100*sizeof(char));
	free(data);
	data = NULL;
	if (data)
	{
		use(data); // GOOD
	}
}

void test4()
{
	char* data;
	data = (char *)malloc(100*sizeof(char));
	free(data);
	if (data)
	{
		use(data); // BAD
	}
}

char* returnsFreedData(int i)
{
	char* data;
	data = (char *)malloc(100*sizeof(char));
	if (i > 0)
	{
		free(data);
	}
	return data;
}

void test5()
{
	char* data = returnsFreedData(1);
	use(data); // BAD (NOT REPORTED)
}

void test6()
{
	char *data, *data2;
	data = (char *)malloc(100*sizeof(char));
	data2 = data;
	free(data);
	use(data2); // BAD (NOT REPORTED)
}

void test7()
{
	char *data, *data2;
	data = (char *)malloc(100*sizeof(char));
	data2 = data;
	free(data);
	data2 = NULL;
	use(data); // BAD
}

void test8()
{
	char *data, *data2;
	data2 = (char *)malloc(100*sizeof(char));
	data = data2;
	free(data);
	data2 = NULL;
	use(data); // BAD
}

void noReturnWrapper() { noReturn(); }

void test9()
{
	char *data, *data2;
	free(data);
	noReturnWrapper();
	use(data); // GOOD
}

void test10()
{
	for (char *data; true; data = NULL)
	{
		use(data); // GOOD
		free(data);
	}
}

class myClass
{
public:
	myClass() { }
	
	void myMethod() { }
};

void test11() {
	myClass* c = new myClass();
	delete(c);
	c->myMethod(); // BAD
	(*c).myMethod(); // BAD
}

template<class T> T test()
{
	T* x;
	use(x); // GOOD
	delete x;
	use(x); // BAD
}

void test12(int count)
{
	char* data = NULL;
	free(data);
	for (int i = 0; i < count; i++)
	{
		data = NULL;
	}
	use(data); // BAD
}

void test13()
{
	char* data = NULL;
	free(data);
	for (int i = 0; i < 2; i++)
	{
		data = NULL;
	}
	use(data); // GOOD
}

void test14()
{
	char* data = NULL;
	free(data);
	for (int i = 0; i < 2; i++)
	{
		data = NULL;
		free(data);
	}
	use(data); // BAD
}

template<class T> T test15()
{
	T* x;
	use(x); // GOOD
	delete x;
	use(x); // BAD
}
void test15runner(void)
{
  test15<char>();
}

void regression_test_for_static_var_handling()
{
	static char *data;
	data = (char *)malloc(100*sizeof(char));
	free(data);
	data = (char *)malloc(100*sizeof(char));
	use(data); // GOOD
}

void useIntPointer1(int *ptr)
{
	int i = *ptr;
}

void useIntPointer2(int *ptr)
{
	int i = ptr[0];
}

void useIntPointerIndirect(int *ptr)
{
	useIntPointer1(ptr);
}

void dontUseIntPointer1(int *ptr)
{
	int i = 0;
}

void dontUseIntPointer2(int *ptr)
{
	int *i = ptr;
}

int *global_ptr1 = (int *)malloc(sizeof(int));
int *global_ptr2;

void test16()
{
	int *a = (int *)malloc(sizeof(int));
	int *b = (int *)malloc(sizeof(int));
	int *c = (int *)malloc(sizeof(int));
	int *d = (int *)malloc(sizeof(int));
	int *e = (int *)malloc(sizeof(int));
	global_ptr2 = (int *)malloc(sizeof(int));

	useIntPointer1(a); // GOOD
	useIntPointer2(b); // GOOD
	dontUseIntPointer1(c); // GOOD
	dontUseIntPointer2(d); // GOOD
	useIntPointerIndirect(e); // GOOD
	useIntPointer1(global_ptr1); // GOOD
	useIntPointer1(global_ptr2); // GOOD

	free(a);
	free(b);
	free(c);
	free(d);
	free(e);
	free(global_ptr1);
	free(global_ptr2);

	useIntPointer1(a); // BAD
	useIntPointer2(b); // BAD
	dontUseIntPointer1(c); // GOOD
	dontUseIntPointer2(d); // GOOD
	useIntPointerIndirect(e); // BAD
	useIntPointer1(global_ptr1); // BAD [NOT DETECTED]
	useIntPointer1(global_ptr2); // BAD [NOT DETECTED]
}

bool cond();

void test17()
{
	int *a = (int *)malloc(sizeof(int));
	int *b = (int *)malloc(sizeof(int));
	int *c = (int *)malloc(sizeof(int));
	int *d = (int *)malloc(sizeof(int));
	int *e = (int *)malloc(sizeof(int));

	for (int i = 0; i < 10; i++)
	{
		useIntPointer1(a); // BAD
		useIntPointer1(b); // GOOD (always allocated at this point in the loop)
		useIntPointer1(c); // BAD
		useIntPointer1(d); // GOOD (only freed in the final loop iteration) [FALSE POSITIVE]

		free(a); // BAD (`a` is freed multiple times)
		free(b);
		if (i == 0) free(c); // GOOD [FALSE POSITIVE]
		if (i == 9) free(d); // GOOD [FALSE POSITIVE]

		useIntPointer1(a); // BAD
		useIntPointer1(b); // BAD
		useIntPointer1(c); // BAD
		useIntPointer1(d); // BAD

		b = (int *)malloc(sizeof(int));
	}

	while (e)
	{
		useIntPointer1(e); // GOOD (only freed in the final loop iteration)

		if (cond())
		{
			free(e);
			e = 0;
		}
	}
}

void test18()
{
	int *ptr = (int *)malloc(sizeof(int));
	bool b;

	if (cond())
	{
		free(ptr);
		b = true;
	}
	if (b)
	{
		useIntPointer1(ptr); // GOOD [FALSE POSITIVE]
	}
}

void test19()
{
	int *ptr = (int *)malloc(sizeof(int));

	if (cond())
	{
		free(ptr);
		ptr = 0;
	}
	if (ptr)
	{
		useIntPointer1(ptr); // GOOD
	}
}

void test20()
{
	int *ptr = (int *)malloc(sizeof(int));

	if (cond())
	{
		free(ptr);
	}
	useIntPointer1(ptr); // BAD
}

struct container
{
public:
	int *p1, *p2;
};

void test21()
{
	container c, d;

	c.p1 = (int *)malloc(sizeof(int));
	c.p2 = (int *)malloc(sizeof(int));
	d.p1 = (int *)malloc(sizeof(int));
	d.p2 = (int *)malloc(sizeof(int));

	free(c.p1);

	useIntPointer1(c.p1); // BAD [NOT DETECTED]
	useIntPointer1(c.p2); // GOOD
	useIntPointer1(d.p1); // GOOD
	useIntPointer1(d.p2); // GOOD
}

import pytest


@pytest.fixture
def fixture():
    pass

def fixture_wrapper():
    @pytest.fixture
    def delegate():
        pass
    return delegate

@fixture_wrapper
def wrapped_fixture():
    pass

def not_a_fixture():
    pass

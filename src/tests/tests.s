.include "test_framework.s"

start_tests

__CATEGORY__ ; Basic test
    __CASE__ ; test 1
        lda #12
        TEST_a_eq_literal $12
end_tests

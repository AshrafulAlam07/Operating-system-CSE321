#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

struct SearchParams {
    int *sequence;      
    int max_index;      
    int total_queries;  
};


void *fib_generator(void *arg) {
    int limit = *(int *)arg;

    int *series = (int *)malloc((limit + 1) * sizeof(int));
    if (series == NULL) {
        perror("Memory allocation failed");
        pthread_exit(NULL);
    }

    if (limit >= 0) series[0] = 0;
    if (limit >= 1) series[1] = 1;

    for (int i = 2; i <= limit; i++) {
        series[i] = series[i - 1] + series[i - 2];
    }

    pthread_exit((void *)series);
}


void *fib_searcher(void *arg) {
    struct SearchParams *params = (struct SearchParams *)arg;
    int query_index;

    for (int i = 0; i < params->total_queries; i++) {
        printf("Enter search %d:\n", i + 1);
        scanf("%d", &query_index);

        if (query_index >= 0 && query_index <= params->max_index) {
            printf("result of search #%d = %d\n", i + 1, params->sequence[query_index]);
        } else {
            printf("result of search #%d = -1\n", i + 1);
        }
    }

    pthread_exit(NULL);
}

int main() {
    int term_limit;
    int num_searches;
    pthread_t gen_thread, search_thread;

    printf("Enter the term of fibonacci sequence:\n");
    scanf("%d", &term_limit);

    if (term_limit < 0 || term_limit > 40) {
        printf("n must be between 0 and 40.\n");
        return 1;
    }


    pthread_create(&gen_thread, NULL, fib_generator, &term_limit);

    void *result_ptr;
    pthread_join(gen_thread, &result_ptr);
    int *fib_series = (int *)result_ptr;
    
    for (int i = 0; i <= term_limit; i++) {
        printf("a[%d] = %d\n", i, fib_series[i]);
    }

    printf("How many numbers you are willing to search?:\n");
    scanf("%d", &num_searches);

    struct SearchParams params;
    params.sequence = fib_series;
    params.max_index = term_limit;
    params.total_queries = num_searches;

    pthread_create(&search_thread, NULL, fib_searcher, &params);
    pthread_join(search_thread, NULL);

    free(fib_series);
    return 0;
}

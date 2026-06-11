#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

pthread_mutex_t mutex_table;
sem_t sem_table_free;
sem_t sem_for_A;
sem_t sem_for_B;
sem_t sem_for_C;

void* supplier_thread(void* arg) {
    int rounds = *(int*)arg;
    for (int step = 0; step < rounds; step++) {
        sem_wait(&sem_table_free);
        pthread_mutex_lock(&mutex_table);
        if (step % 3 == 0) {
            printf("Supplier places: Bread and Cheese\n");
            sem_post(&sem_for_C);  
        } else if (step % 3 == 1) {
            printf("Supplier places: Cheese and Lettuce\n");
            sem_post(&sem_for_A);  
        } else {
            printf("Supplier places: Bread and Lettuce\n");
            sem_post(&sem_for_B);  
        }
        pthread_mutex_unlock(&mutex_table);
    }
    return NULL;
}

void* bread_maker(void* arg) {
    while (1) {
        sem_wait(&sem_for_A);
        pthread_mutex_lock(&mutex_table);

        printf("Maker A picks up Cheese and Lettuce\n");
        pthread_mutex_unlock(&mutex_table);

        printf("Maker A is making the sandwich...\n");
        sleep(1);
        printf("Maker A finished making the sandwich and eats it\n");
        printf("Maker A signals Supplier\n");

        sem_post(&sem_table_free);
    }
}

void* cheese_maker(void* arg) {
    while (1) {
        sem_wait(&sem_for_B);
        pthread_mutex_lock(&mutex_table);

        printf("Maker B picks up Bread and Lettuce\n");
        pthread_mutex_unlock(&mutex_table);

        printf("Maker B is making the sandwich...\n");
        sleep(1);
        printf("Maker B finished making the sandwich and eats it\n");
        printf("Maker B signals Supplier\n");

        sem_post(&sem_table_free);
    }
}

void* lettuce_maker(void* arg) {
    while (1) {
        sem_wait(&sem_for_C);
        pthread_mutex_lock(&mutex_table);

        printf("Maker C picks up Bread and Cheese\n");
        pthread_mutex_unlock(&mutex_table);

        printf("Maker C is making the sandwich...\n");
        sleep(1);
        printf("Maker C finished making the sandwich and eats it\n");
        printf("Maker C signals Supplier\n");

        sem_post(&sem_table_free);
    }
}

int main() {
    int total_rounds;
    printf("Enter number of times supplier places ingredients: ");
    scanf("%d", &total_rounds);
    pthread_mutex_init(&mutex_table, NULL);
    sem_init(&sem_table_free, 0, 1);
    sem_init(&sem_for_A, 0, 0);
    sem_init(&sem_for_B, 0, 0);
    sem_init(&sem_for_C, 0, 0);


    pthread_t t_supplier, t_A, t_B, t_C;
    pthread_create(&t_supplier, NULL, supplier_thread, &total_rounds);
    pthread_create(&t_A, NULL, bread_maker, NULL);
    pthread_create(&t_B, NULL, cheese_maker, NULL);
    pthread_create(&t_C, NULL, lettuce_maker, NULL);

    pthread_join(t_supplier, NULL);

    sleep(2);

    pthread_mutex_destroy(&mutex_table);
    sem_destroy(&sem_table_free);
    sem_destroy(&sem_for_A);
    sem_destroy(&sem_for_B);
    sem_destroy(&sem_for_C);

    return 0;
}

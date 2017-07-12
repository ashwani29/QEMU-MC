This page links to a C program called **RACEY**. **RACEY** is useful for testing methods for deterministic execution or record/reply. **RACEY** computes a signature whose value is exceedingly sensitive to the order of unsynchronized data races. On a non-deterministic system, each of tens of thousands of **RACEY** runs produces a unique signature value.

To test an allegedly deterministic system, run **RACEY** so that the instructions of multiple threads run concurrently. If **RACEY** ever produces different signature values, then the system is non-deterministic. If **RACEY** repeatedly produces the same signature value, your system *may be* deterministic.

The kernel of **RACEY** uses a multiplicative congruential pseudo-random number generator [Knu] named **mix()**:
```C
#define   PRIME1   103072243
#define   PRIME2   103995407
unsigned mix(unsigned i, unsigned j) {
  return (i + j * PRIME2) % PRIME1;
  }
```
Each thread races with other concurrent threads to:
- take its component of a signature **sig[threadId]**,
- **mix** values in an integer array **m[...].value**,
- obtain a new *sig[threadId]*,
- and repeat many times.

```C
#define   MAX_LOOP 1000
#define   MAX_ELEM 64
  for(i = 0 ; i < MAX_LOOP; i++) {
    unsigned num = sig[threadId];
    unsigned index1 = num%MAX_ELEM;
    unsigned index2;
    num = mix(num, m[index1].value);
    index2 = num%MAX_ELEM;
    num = mix(num, m[index2].value);
    m[index2].value = num;
    sig[threadId] = num;
     }
```
Since **mix()** is exceedingly NON-associative, any reordering of conflicting accesses (reads/writes or writes/writes) will change the final signature value with high probability.

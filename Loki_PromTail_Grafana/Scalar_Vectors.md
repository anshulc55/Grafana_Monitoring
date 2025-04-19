# Scalar Vectors and Series of Scalar Vectors

### Examples

- The count of jobs at 1-minute time intervals:
    ```logql
    count_over_time({job="varlogs"}[1m])
    ```
- The rate of logs per minute. Rate is similar to count_over_time but shows the entries per second:
    ```logql
    rate({job="varlogs"}[1m])
    ```
    **Info**  
    rate = count_over_time / 60 / range(m)  
    eg,  
    12 / 60 / 2 = 0.1

- The count of errors at 1-hour time intervals:
    ```logql
    count_over_time({job="varlogs"} |= "error" [1h])
    ```

## Aggregate Functions

An aggregate function converts multiple series of vectors into a single vector.

- **sum**: Calculate the total of all vectors in the range at time
- **min**: Show the minimum value from all vectors in the range at time
- **max**: Show the maximum value from all vectors in the range at time
- **avg**: Calculate the average of the values from all vectors in the range at time
- **stddev**: Calculate the standard deviation of the values from all vectors in the range at time
- **stdvar**: Calculate the standard variance of the values from all vectors in the range at time
- **count**: Count the number of elements in all vectors in the range at time
- **bottomk**: Select lowest `k` values in all the vectors in the range at time
- **topk**: Select highest `k` values in all the vectors in the range at time

**Note**  
`bottomk` and `topk` don't produce a vector, but a series of vectors containing the `k` number of vectors in the time range.

### Examples

- Calculate the total of all vectors in the range at time:
    ```logql
    sum(count_over_time({job="varlogs"}[1m]))
    ```

- Show the minimum value from all vectors in the range at time:
    ```logql
    min(count_over_time({job="varlogs"}[1m]))
    ```

- Show the maximum value from all vectors in the range at time:
    ```logql
    max(count_over_time({job="varlogs"}[1m]))
    ```

- Show only the top 2 values from all vectors in the range at time:
    ```logql
    topk(2, count_over_time({job="varlogs"}[1h]))
    ```

## Aggregate Group

Convert a scalar vector into a series of vectors grouped by filename.

### Examples

- Group a single log stream by filename:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) by (filename)
    ```

- Group multiple log streams by host:
    ```logql
    sum(count_over_time({job=~"varlogs"}[1m])) by (host)
    ```

- Group multiple log streams by filename and host:
    ```logql
    sum(count_over_time({job=~"varlogs"}[1m])) by (filename,host)
    ```

## Comparison Operators

Comparison Operators are used for testing numeric values present in scalars and vectors.

- **==**: Equality
- **!=**: Inequality
- **>**: Greater than
- **>=**: Greater than or equal to
- **<**: Less than
- **<=**: Less than or equal to

### Examples

- Returns values greater than 4:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) > 4
    ```

- Returns values less than or equal to 1:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) <= 1
    ```

## Logical Operators

These can be applied to both vectors and series of vectors.

- **and**: Both sides must be true
- **or**: Either side must be true
- **unless**: Return values unless value

### Examples

- Returns values greater than 4 or values less than or equal to 1:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) > 4 or sum(count_over_time({job="varlogs"}[1m])) <= 1
    ```

- Return values between 100 and 200:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) > 100 and sum(count_over_time({job="varlogs"}[1m])) < 200
    ```

## Arithmetic Operators

- **+**: Add
- **-**: Subtract
- **\***: Multiply
- **/**: Divide
- **%**: Modulus
- **^**: Power/Exponentiation

### Examples

- Multiply the sum of count_over_time by 10 and then take modulus:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) * 10 and sum(count_over_time({job="varlogs"}[1m])) % 2
    ```

## Operator Order

Many operators can be used at a time. The order follows the PEMDAS construct. PEMDAS is an acronym for the words parenthesis, exponents, multiplication, division, addition, subtraction.

### Examples

- A nonsensical example:
    ```logql
    sum(count_over_time({job="varlogs"}[1m])) % 4 * 2 ^ 2 + 2
    ```
    is the same as:
    ```logql
    ((sum(count_over_time({job="varlogs"}[1m])) % 4 * (2 ^ 2)) + 2)
    ```

- Proving that `count_over_time / 60 / range(m)` = `rate`:
    ```logql
    rate({job="varlogs"}[2m]) == count_over_time({job="varlogs"}[2m]) / 60 / 2
    ```
    is the same as:
    ```logql
    rate({job="varlogs"}[2m]) == ((count_over_time({job="varlogs"}[2m]) / 60) / 2)
    ```

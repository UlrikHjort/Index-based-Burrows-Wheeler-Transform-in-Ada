# Index based Burrows-Wheeler Transform in Ada

This is an Index-based implementation of the **[Burrows-Wheeler Transform (BWT)](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform)** and its inverse in Ada. No sentinel needed.

## What is the Burrows-Wheeler Transform?

The Burrows-Wheeler Transform reorganizes a string of characters into runs of similar characters. This makes it useful for compression, as repeated characters can be encoded more efficiently.

## How It Works

### Forward Transform (BWT)

The forward transform takes an input string and produces a transformed output plus an index number.

**Algorithm Steps:**

1. **Generate all rotations** of the input string
   - For "BANANA", create: BANANA, ANANAB, NANABA, ANABAN, NABANA, ABANAN

2. **Sort the rotations** lexicographically (alphabetically)
   ```
   ABANAN
   ANABAN
   ANANAB
   BANANA  <- original string (index 3)
   NABANA
   NANABA
   ```

3. **Take the last character** of each sorted rotation
   - Reading down the last column: N, N, B, A, A, A
   - Result: "NNBAAA"

4. **Record the index** where the original string appears in the sorted list
   - In this case, index 3

**Output:** Transformed string "NNBAAA" and index 3

### Inverse Transform (BWT Inverse)

The inverse transform takes the transformed string and index, and reconstructs the original.

**Algorithm Steps:**

1. **Prepare the columns:**
   - Last column (L): The transformed string "NNBAAA"
   - First column (F): Sort the last column to get "AAABNN"

2. **Build the next-index mapping:**
   - For each character in the last column, find which occurrence it is (1st N, 2nd N, 1st B, etc.)
   - Map it to the same occurrence in the first column
   
   Example for "NNBAAA":
   ```
   Last[0] = 'N' (1st N) -> maps to First[4] (1st N in sorted) -> Next[0] = 4
   Last[1] = 'N' (2nd N) -> maps to First[5] (2nd N in sorted) -> Next[1] = 5
   Last[2] = 'B' (1st B) -> maps to First[3] (1st B in sorted) -> Next[2] = 3
   Last[3] = 'A' (1st A) -> maps to First[0] (1st A in sorted) -> Next[3] = 0
   Last[4] = 'A' (2nd A) -> maps to First[1] (2nd A in sorted) -> Next[4] = 1
   Last[5] = 'A' (3rd A) -> maps to First[2] (3rd A in sorted) -> Next[5] = 2
   ```

3. **Follow the chain** starting from the given index:
   - Start at index 3
   - Read First[3] = 'B', next index = Next[3] = 0
   - Read First[0] = 'A', next index = Next[0] = 4
   - Read First[4] = 'N', next index = Next[4] = 1
   - Read First[1] = 'A', next index = Next[1] = 5
   - Read First[5] = 'N', next index = Next[5] = 2
   - Read First[2] = 'A', next index = Next[2] = 3 (back to start)
   
   Result: "BANANA"

## Code Structure

### Main Components

- **`BWT_Transform`**: Performs the forward transform
  - Takes an input string
  - Returns the transformed string and the index
  
- **`BWT_Inverse`**: Performs the inverse transform
  - Takes the transformed string and index
  - Returns the original string

### Helper Functions

- **`Rotate`**: Creates a rotation of a string by shifting characters
- **`Sort_Rotations`**: Sorts the rotation list using bubble sort
- **`Less_Than`**: Comparison function for lexicographic ordering

## Compilation and Usage

Compile with GNAT (GNU Ada compiler):

```bash
gnatmake burrows_wheeler.adb
```

Run the program:

```bash
./burrows_wheeler
```

The program will transform "BANANA", then reverse the transformation and verify the result.

## Example Output

```
========================================
  Burrows-Wheeler Transform Test Suite
========================================

Test  1: Classic example
----------------------------------------
Original:    BANANA
BWT Encoded: NNBAAA
Index:       3
Decoded:     BANANA
Result:      ✓ PASS
----------------------------------------

Test  2: Plural form
----------------------------------------
Original:    BANANAS
BWT Encoded: BNNSAAA
Index:       3
Decoded:     BANANAS
Result:      ✓ PASS
----------------------------------------

... (additional tests) ...

========================================
  Test Summary
========================================
Total tests:  10
Passed:       10
Failed:       0

✓ All tests passed!
```

## Test Cases

The program includes a comprehensive test suite with various types of input:

1. **Classic example** - "BANANA": The standard BWT demonstration
2. **Plural form** - "BANANAS": Tests handling of additional characters
3. **Short string** - "ABC": Simple three-character string
4. **Repeated pairs** - "AABBCC": Tests repeated character pairs
5. **Single character** - "X": Minimal edge case
6. **Palindrome** - "RACECAR": Symmetric string
7. **Mixed case** - "HelloWorld": Upper and lowercase letters
8. **With spaces** - "THE QUICK BROWN FOX": String containing spaces
9. **Numbers** - "1234567890": Numeric characters
10. **Punctuation** - "Hello, World!": Special characters and punctuation

### Known Limitations

**Strings with all identical characters** (e.g., "AAAAAA") are not currently supported. When all characters in the input are the same, all rotations become identical after sorting, which creates ambiguity in the inverse transform. This is a degenerate edge case that would require special handling. In practice, such strings are trivial to compress and rarely occur in real-world data.

If you need to handle such cases, you could add a pre-check that detects all-same-character strings and handles them separately (the BWT would just be the same string, and the index could be 0).

There could be other corner cases that is not covered by this implementation.  


This implementation uses bubble sort for simplicity, which has O(n<sup>2</sup>) time complexity. For very large strings, you might want to use a more efficient sorting algorithm. However, for educational purposes and moderate-sized inputs, this implementation works well.

## References

- **[Burrows-Wheeler Transform (BWT)](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform)**

- **[GNAT](https://en.wikipedia.org/wiki/GNAT)**

- **[Ada](https://en.wikipedia.org/wiki/Ada_(programming_language))**

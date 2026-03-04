-- ***************************************************************************
--             Index based Burrows-Wheeler Transform
--
--           Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************

with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

procedure Burrows_Wheeler is
   
   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Unbounded_String);
   use String_Vectors;
   
   -- Burrows-Wheeler Transform
   procedure BWT_Transform 
     (Input  : String;
      Output : out Unbounded_String;
      Index  : out Natural) is
      
      Rotations : String_Vectors.Vector;
      Temp_Str  : Unbounded_String;
      N         : constant Natural := Input'Length;
      
      -- Create a rotation of the string
      function Rotate (S : String; K : Natural) return String is
         Result : String (1 .. S'Length);
      begin
         for I in S'Range loop
            Result (I) := S (((I - S'First + K) mod S'Length) + S'First);
         end loop;
         return Result;
      end Rotate;
      
      -- Lexicographic comparison for sorting
      function Less_Than (Left, Right : Unbounded_String) return Boolean is
      begin
         return To_String (Left) < To_String (Right);
      end Less_Than;
      
      -- Simple bubble sort for the rotations
      procedure Sort_Rotations is
         Swapped : Boolean;
         Temp    : Unbounded_String;
      begin
         loop
            Swapped := False;
            for I in 0 .. Integer (Rotations.Length) - 2 loop
               if not Less_Than (Rotations.Element (I), 
                                 Rotations.Element (I + 1)) then
                  Temp := Rotations.Element (I);
                  Rotations.Replace_Element (I, Rotations.Element (I + 1));
                  Rotations.Replace_Element (I + 1, Temp);
                  Swapped := True;
               end if;
            end loop;
            exit when not Swapped;
         end loop;
      end Sort_Rotations;
      
   begin
      -- Generate all rotations
      for I in 0 .. N - 1 loop
         Rotations.Append (To_Unbounded_String (Rotate (Input, I)));
      end loop;
      
      -- Sort rotations lexicographically
      Sort_Rotations;
      
      -- Build output from last character of each rotation
      Output := To_Unbounded_String ("");
      Index := 0;  -- Default to 0 if not found
      
      for I in 0 .. Integer (Rotations.Length) - 1 loop
         declare
            Rot : constant String := To_String (Rotations.Element (I));
            Is_Original : Boolean := True;
         begin
            Append (Output, Rot (Rot'Last));
            
            -- Find the original string position (index)
            -- Check character by character to handle all-same-character case
            if Rot'Length = Input'Length then
               for J in Input'Range loop
                  if Rot (J - Input'First + Rot'First) /= Input (J) then
                     Is_Original := False;
                     exit;
                  end if;
               end loop;
               
               if Is_Original then
                  Index := I;
               end if;
            end if;
         end;
      end loop;
   end BWT_Transform;
   
   -- Burrows-Wheeler Inverse Transform
   function BWT_Inverse 
     (Encoded : String;
      Index   : Natural) return String is
      
      N : constant Natural := Encoded'Length;
      
      type Index_Array is array (Natural range <>) of Natural;
      type Char_Array is array (Natural range <>) of Character;
      
      Next_Index : Index_Array (0 .. N - 1);
      First_Col  : Char_Array (0 .. N - 1);
      Last_Col   : Char_Array (0 .. N - 1);
      
      -- Count array for character occurrences
      Count : array (Character) of Natural := (others => 0);
      
      Result : String (1 .. N);
      Curr   : Natural := Index;
      
   begin
      -- Store the last column
      for I in Encoded'Range loop
         Last_Col (I - Encoded'First) := Encoded (I);
      end loop;
      
      -- Copy to first column and sort to get the first column
      First_Col := Last_Col;
      
      -- Simple bubble sort to get the first column
      declare
         Swapped : Boolean;
         Temp    : Character;
      begin
         loop
            Swapped := False;
            for I in 0 .. N - 2 loop
               if First_Col (I) > First_Col (I + 1) then
                  Temp := First_Col (I);
                  First_Col (I) := First_Col (I + 1);
                  First_Col (I + 1) := Temp;
                  Swapped := True;
               end if;
            end loop;
            exit when not Swapped;
         end loop;
      end;
      
      -- Build next_index: for each position in first column,
      -- find where it goes in the last column
      for I in 0 .. N - 1 loop
         declare
            C : constant Character := First_Col (I);
            Occurrence : Natural := 0;
            Found : Boolean := False;
         begin
            -- Count how many times this char appeared before position I in first col
            for J in 0 .. I - 1 loop
               if First_Col (J) = C then
                  Occurrence := Occurrence + 1;
               end if;
            end loop;
            
            -- Find the (Occurrence+1)-th occurrence of C in last column
            declare
               Found_Count : Natural := 0;
            begin
               for J in 0 .. N - 1 loop
                  if Last_Col (J) = C then
                     if Found_Count = Occurrence then
                        Next_Index (I) := J;
                        Found := True;
                        exit;
                     end if;
                     Found_Count := Found_Count + 1;
                  end if;
               end loop;
            end;
            
            -- Safety check: if not found, this is a bug
            if not Found then
               raise Constraint_Error with "Failed to build next_index mapping";
            end if;
         end;
      end loop;
      
      -- Reconstruct the original string by following the chain
      for I in Result'Range loop
         Result (I) := First_Col (Curr);
         Curr := Next_Index (Curr);
      end loop;
      
      return Result;
   end BWT_Inverse;
   
   -- Test procedure
   procedure Test_BWT (Input : String) is
      Encoded : Unbounded_String;
      Idx     : Natural;
      Decoded : String (1 .. Input'Length);
      Success : Boolean;
   begin
      Ada.Text_IO.Put_Line ("Original:    " & Input);
      
      -- Perform BWT
      BWT_Transform (Input, Encoded, Idx);
      Ada.Text_IO.Put_Line ("BWT Encoded: " & To_String (Encoded));
      Ada.Text_IO.Put_Line ("Index:      " & Natural'Image (Idx));
      
      -- Perform inverse BWT
      Decoded := BWT_Inverse (To_String (Encoded), Idx);
      Ada.Text_IO.Put_Line ("Decoded:     " & Decoded);
      
      Success := (Decoded = Input);
      if Success then
         Ada.Text_IO.Put_Line ("Result:      ✓ PASS");
      else
         Ada.Text_IO.Put_Line ("Result:      ✗ FAIL - Decoded string does not match!");
      end if;
      
      Ada.Text_IO.Put_Line ("----------------------------------------");
   end Test_BWT;
   
   -- Test cases
   type Test_Case is record
      Name  : Unbounded_String;
      Input : Unbounded_String;
   end record;
   
   type Test_Array is array (Positive range <>) of Test_Case;
   
   Tests : constant Test_Array := (
      (To_Unbounded_String ("Classic example"),
       To_Unbounded_String ("BANANA")),
      (To_Unbounded_String ("'Extended' classic"),
       To_Unbounded_String ("BANANAS")),
      (To_Unbounded_String ("Short string"),
       To_Unbounded_String ("ABC")),
      (To_Unbounded_String ("Repeated pairs"),
       To_Unbounded_String ("AABBCC")),
      (To_Unbounded_String ("Single character"),
       To_Unbounded_String ("X")),
      (To_Unbounded_String ("Palindrome"),
       To_Unbounded_String ("RACECAR")),
      (To_Unbounded_String ("Mixed case"),
       To_Unbounded_String ("HelloWorld")),
      (To_Unbounded_String ("With spaces"),
       To_Unbounded_String ("THE QUICK BROWN FOX")),
      (To_Unbounded_String ("Numbers"),
       To_Unbounded_String ("1234567890")),
      (To_Unbounded_String ("Punctuation"),
       To_Unbounded_String ("Hello, World!"))
   );
   
   Passed : Natural := 0;
   Failed : Natural := 0;
   
begin
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line ("  Burrows-Wheeler Transform Test Suite");
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.New_Line;
   
   for I in Tests'Range loop
      Ada.Text_IO.Put_Line ("Test " & Natural'Image (I) & ": " & To_String (Tests (I).Name));
      Ada.Text_IO.Put_Line ("----------------------------------------");
      
      declare
         Input   : constant String := To_String (Tests (I).Input);
         Encoded : Unbounded_String;
         Idx     : Natural;
         Decoded : String (1 .. Input'Length);
      begin
         Ada.Text_IO.Put_Line ("Original:    " & Input);
         
         -- Perform BWT
         BWT_Transform (Input, Encoded, Idx);
         Ada.Text_IO.Put_Line ("BWT Encoded: " & To_String (Encoded));
         Ada.Text_IO.Put_Line ("Index:      " & Natural'Image (Idx));
         
         -- Perform inverse BWT
         Decoded := BWT_Inverse (To_String (Encoded), Idx);
         Ada.Text_IO.Put_Line ("Decoded:     " & Decoded);
         
         if Decoded = Input then
            Ada.Text_IO.Put_Line ("Result:      ✓ PASS");
            Passed := Passed + 1;
         else
            Ada.Text_IO.Put_Line ("Result:      ✗ FAIL");
            Failed := Failed + 1;
         end if;
      end;
      
      Ada.Text_IO.Put_Line ("----------------------------------------");
      Ada.Text_IO.New_Line;
   end loop;
   
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line ("  Test Summary");
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line ("Total tests: " & Natural'Image (Tests'Length));
   Ada.Text_IO.Put_Line ("Passed:     " & Natural'Image (Passed));
   Ada.Text_IO.Put_Line ("Failed:     " & Natural'Image (Failed));
   Ada.Text_IO.New_Line;
   
   if Failed = 0 then
      Ada.Text_IO.Put_Line ("✓ All tests passed!");
   else
      Ada.Text_IO.Put_Line ("✗ Some tests failed.");
   end if;
   
end Burrows_Wheeler;

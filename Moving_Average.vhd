Library IEEE ;
Use IEEE.STD_Logic_1164.All ;
Use IEEE.Numeric_STD.All ;

Entity Moving_Average Is

   Generic(
      Input_Word_Length               : Integer := 8 ;
      Input_Fraction_Length           : Integer := 7 ;
      Output_Word_Length              : Integer := 8 ;
      Output_Fraction_Length          : Integer := 7 ;
      Window_Length                   : Integer := 100 ;
      Ceil_Log2_Window_Length         : Integer := 7 ;
      Divisor_Inverse_Word_Length     : Integer := 11 ;
      Divisor_Inverse_Fraction_Length : Integer := 10 ;
      Divisor_Inverse                 : Integer := 11
   ) ;

   Port(
      Clock             : In  STD_Logic ;
      Clock_Enable      : In  STD_Logic ;
      Input             : In  Signed(Input_Word_Length-1 Downto 0) ;
      Output            : Out Signed(Output_Word_Length-1 Downto 0) 
   ) ;

End Moving_Average ;

Architecture Behavioral Of Moving_Average Is

   Signal Input_Register         : Signed(Input_Word_Length-1 Downto 0)                                                     := To_Signed(0,Input_Word_Length) ;
   Signal Clock_Enable_Register  : STD_LOGIC                                                                                := '0' ;
   Signal Output_Register        : Signed(Output_Word_Length-1 Downto 0)	                                                 := To_Signed(0,Input_Word_Length) ;

   Signal Accumulator            : Signed(Input_Word_Length+Ceil_Log2_Window_Length-1 Downto 0)	                            := To_Signed(0,Input_Word_Length+Ceil_Log2_Window_Length) ;

   Type   Delay_Line_Type Is Array (0 To Window_Length-1) Of Signed(Input_Word_Length-1 Downto 0) ;
   Signal Delay_Line             : Delay_Line_Type                                                                          := (Others=>To_Signed(0,Input_Word_Length)) ;
   Signal Delay_Line_Output      : Signed(Input_Word_Length-1 Downto 0)                                                     := To_Signed(0,Input_Word_Length) ;

   Signal Counter_In_Delay_Line  : Unsigned(Ceil_Log2_Window_Length-1 Downto 0)                                             := To_Unsigned(0,Ceil_Log2_Window_Length) ;
   Signal Counter_Out_Delay_Line : Unsigned(Ceil_Log2_Window_Length-1 Downto 0)                                             := To_Unsigned(1,Ceil_Log2_Window_Length) ;

   Signal Dividend               : Signed(Input_Word_Length+Ceil_Log2_Window_Length-1 Downto 0)	                            := To_Signed(0,Input_Word_Length+Ceil_Log2_Window_Length) ;
   Signal Quotient               : Signed(Input_Word_Length+Ceil_Log2_Window_Length+Divisor_Inverse_Word_Length-1 Downto 0) := To_Signed(0,Input_Word_Length+Ceil_Log2_Window_Length+Divisor_Inverse_Word_Length) ;
   Alias  Quotient_Quantize      : Signed(Output_Word_Length-1 Downto 0) Is Quotient(Output_Word_Length+Input_Fraction_Length+Divisor_Inverse_Fraction_Length-Output_Fraction_Length-1 Downto Input_Fraction_Length+Divisor_Inverse_Fraction_Length-Output_Fraction_Length) ;

Begin

   Process(Clock)
   Begin

      If Rising_Edge(Clock) Then

      -- Registering Input Ports
         Input_Register             <= Input ;
         Clock_Enable_Register      <= Clock_Enable ;
      -- %%%%%%%%%%%%%%%%%%%%%%%

         If Clock_Enable_Register='1' Then

         -- Input Address Of The Delay Line
				Counter_In_Delay_Line    <= Counter_In_Delay_Line + 1 ;
				If Counter_In_Delay_Line=(Window_Length-1) Then
				   Counter_In_Delay_Line <= To_Unsigned(0,Ceil_Log2_Window_Length) ;
				End If ;

            Counter_Out_Delay_Line    <= Counter_Out_Delay_Line + 1 ;
            If Counter_Out_Delay_Line=(Window_Length-1) Then
               Counter_Out_Delay_Line <= To_Unsigned(0,Ceil_Log2_Window_Length) ;
            End If ;
         -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         -- Delay Line
				Delay_Line(To_Integer(Counter_In_Delay_Line)) <= Input_Register ;
         -- %%%%%%%%%%

         -- Accumulator Calculation
				Delay_Line_Output <= Delay_Line(To_Integer(Counter_Out_Delay_Line)) ;
				Accumulator       <= Accumulator + Input_Register - Delay_Line_Output ;
         -- %%%%%%%%%%%%%%%%%%%%%%%

         -- Calculate Division
            Dividend <= Accumulator ;
				Quotient <= Dividend * To_Signed(Divisor_Inverse,Divisor_Inverse_Word_Length) ;
         -- %%%%%%%%%%%%%%%%%%

         -- Quantize The Division Result for The Output Register
            Output_Register <= Quotient_Quantize ;
         -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			End If ;

		End If ;

	End Process ;

-- Registering Output Ports
   Output <= Output_Register ;
-- %%%%%%%%%%%%%%%%%%%%%%%%

End Behavioral ;
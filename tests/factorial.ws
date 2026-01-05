push_1  { 	}
push_17  { 	   	}
store		 push_2  { 	 }
push_33  { 	    	}
store		 push_3  { 		}
push_32  { 	     }
store		 push_4  { 	  }
push_61  { 				 	}
store		 push_5  { 	 	}
push_10  { 	 	 }
store		 push_6  { 		 }
push_0  {	 }
store		 push_7  { 			}
push_1  { 	}
store		 label
  { }
printing_block_push_6  { 		 }
retrieve			print_as_number	
 	push_2  { 	 }
retrieve			print_as_char	
  push_3  { 		}
retrieve			print_as_char	
  push_4  { 	  }
retrieve			print_as_char	
  push_3  { 		}
retrieve			print_as_char	
  push_7  { 			}
retrieve			print_as_number	
 	push_5  { 	 	}
retrieve			print_as_char	
  increase_counter_block_push_6  { 		 }
push_6  { 		 }
retrieve			push_1  { 	}
add	   store		 calculate_next_factorial_block_push_7  { 			}
push_7  { 			}
retrieve			push_6  { 		 }
retrieve			multiply	  
store		 conditional_return_block_push_6  { 		 }
retrieve			push_1  { 	}
retrieve			subtract	  	jump_if_negative
		{ }
quit


end;sample-from:http://progopedia.com/language/whitespace/
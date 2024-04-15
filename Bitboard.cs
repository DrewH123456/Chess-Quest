using Godot;
using System;
using System.Collections.Generic;

public partial class Bitboard : Godot.Node
{
	// Called when the node enters the scene tree for the first time.
	
	// Arrays of ulongs that represent bitboards of each piece for white and black
	public ulong[] whitePieces = { 0, 0, 0, 0, 0, 0 };
	public ulong[] blackPieces = { 0, 0, 0, 0, 0, 0 };
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	// Represents where each black piece is with a ulong, 1 means piece is there, 0 means otherwise
	public ulong GetBlackBitboard(){
		ulong ans = 0;
		foreach(ulong i in blackPieces){
			ans |= i;
		}
		return ans;
	}
	
	// Represents where each white piece is with a ulong, 1 means piece is there, 0 means otherwise
	public ulong GetWhiteBitboard(){
		ulong ans = 0;
		foreach(ulong i in whitePieces){
			ans |= i;
		}
		return ans;
	}

	// Clears bitboard for white and black pieces, setting them all to zeroes
	public void ClearBitboard()
	{
		Array.Clear(whitePieces);
		Array.Clear(blackPieces);
	}
	
	// Creates bitboard for each piece based on given fen
	public void InitBitBoard(string fen)
	{
		ClearBitboard();
		string[] fen_split = fen.Split(" ");
		foreach (char i in fen_split[0])
		{
			if (i.Equals('/'))
				continue;
			// Shifts each bitboard by given int amount
			if (Char.IsDigit(i))
			{
				int shiftAmount = int.Parse(i.ToString());
				LeftShift(shiftAmount);
				continue;
			}
			// Fills in bitboard of given piece, represented by letter, uppercase for white, lowercase for black
			LeftShift(1);
			if (Char.IsUpper(i))
			{
				whitePieces[DataHandlerCS.FenDict[Char.ToLower(i)]] |= 1UL;
			}
			else
			{
				blackPieces[DataHandlerCS.FenDict[i]] |= 1UL;
			}
		}
		GD.Print("Bitboard init successful");
	}

	// Shifts bits in whitePieces and blackPieces by shiftAmount
	private void LeftShift(int shiftAmount)
	{
		for (int piece = 0; piece < blackPieces.Length; piece++)
		{
			blackPieces[piece] <<= shiftAmount;
		}
		for (int piece = 0; piece < whitePieces.Length; piece++)
		{
			whitePieces[piece] <<= shiftAmount;
		}
	}
	
	public void RemovePiece(int location, int pieceType) {
		if(pieceType > 5) {
			blackPieces[pieceType%6] &= ~(1UL<<location);
		} else {
			whitePieces[pieceType%6] &= ~(1UL<<location);
		}
	}
	
	public void AddPiece(int location, int pieceType) {
		if(pieceType > 5) {
			blackPieces[pieceType%6] |= 1UL<<location;
		} else {
			whitePieces[pieceType%6] |= 1UL<<location;
		}
	}
	
	public ulong GetBitboard(){
		return blackPieces[5];
	}
}

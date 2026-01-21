// supabase/functions/messages/messagesRepo.ts
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { CreateMessageRequest } from "./requestTypes.ts";

export interface MessageInsertRow {
  author_id: string;           // NOT NULL
  content: string;             // NOT NULL
  latitude: number;            // NOT NULL
  longitude: number;           // NOT NULL
  place_id?: string | null;    // nullable uuid
}

export interface PlaceInsertRow {
  place_id: string;
  name: string;
  latitude: number;
  longitude: number;
  address?: string | null;
}

async function upsertPlace(
  client: SupabaseClient,
  place: { place_id: string; name: string; latitude: number; longitude: number; address?: string | null },
): Promise<void> {
  const row: PlaceInsertRow = {
    place_id: place.place_id,
    name: place.name,
    latitude: place.latitude,
    longitude: place.longitude,
    address: place.address ?? null,
  };

  const { error } = await client
    .from("places")
    .upsert(row, { onConflict: "place_id" });

  if (error) throw new Error(`DB_UPSERT_PLACE_FAILED: ${error.message}`);
}

export async function insertMessage(
  client: SupabaseClient,
  userId: string,
  req: CreateMessageRequest,
): Promise<void> {
  // place가 있으면 먼저 places 테이블에 upsert
  if (req.place) {
    await upsertPlace(client, req.place);
  }

  const row: MessageInsertRow = {
    author_id: userId,
    content: req.content,
    latitude: req.latitude,
    longitude: req.longitude,
    place_id: req.place?.place_id ?? null,
  };

  const { error } = await client.from("messages").insert(row);
  if (error) throw new Error(`DB_INSERT_FAILED: ${error.message}`);
}

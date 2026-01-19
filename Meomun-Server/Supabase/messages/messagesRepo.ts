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

export async function insertMessage(
  client: SupabaseClient,
  userId: string,
  req: CreateMessageRequest,
): Promise<void> {
  const row: MessageInsertRow = {
    author_id: userId,
    content: req.content,
    latitude: req.latitude,
    longitude: req.longitude,
    place_id: req.place?.id ?? null,
  };

  const { error } = await client.from("messages").insert(row);
  if (error) throw new Error(`DB_INSERT_FAILED: ${error.message}`);
}

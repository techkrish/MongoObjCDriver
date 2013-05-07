/*
 * Copyright 2013 10gen Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include "mongoc-conn-private.h"
#include "mongoc-error.h"


void
mongoc_conn_init_tcp (mongoc_conn_t *conn,
                      const char    *host,
                      bson_uint16_t  port,
                      const bson_t  *options)
{
   bson_return_if_fail(conn);
   bson_return_if_fail(host);
   bson_return_if_fail(port);

   memset(conn, 0, sizeof *conn);

   conn->type = MONGOC_CONN_TCP;
   conn->fd = -1;
   conn->ping = -1;
   conn->host = bson_strdup(host);
   conn->port = port;

   /*
    * TODO: Fetch timeout values from options.
    */

   if (options) {
   }
}


static bson_bool_t
mongoc_conn_connect_tcp (mongoc_conn_t *conn,
                         bson_error_t  *error)
{
   struct addrinfo hints;
   struct addrinfo *result, *rp;
   char portstr[8];
   int s, sfd;

   bson_return_val_if_fail(conn, FALSE);

   conn->state = MONGOC_CONN_STATE_CONNECTING;

   snprintf(portstr, sizeof portstr, "%hu", conn->port);

   memset(&hints, 0, sizeof hints);
   hints.ai_family = AF_UNSPEC;
   hints.ai_socktype = SOCK_DGRAM;
   hints.ai_flags = 0;
   hints.ai_protocol = 0;

   s = getaddrinfo(conn->host, portstr, &hints, &result);
   if (s != 0) {
      bson_set_error(error,
                     MONGOC_ERROR_CONN,
                     MONGOC_ERROR_CONN_NAME_RESOLUTION,
                     "Failed to resolve hostname.");
      return FALSE;
   }

   for (rp = result; rp; rp = rp->ai_next) {
      sfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
      if (sfd == -1) {
         continue;
      }

      if (connect(sfd, rp->ai_addr, rp->ai_addrlen) != -1) {
         break;
      }

      close(sfd);
   }

   if (!rp) {
      bson_set_error(error,
                     MONGOC_ERROR_CONN,
                     MONGOC_ERROR_CONN_CONNECT,
                     "Failed to connect to target host.");
      freeaddrinfo(result);
      return FALSE;
   }

   freeaddrinfo(result);

   conn->fd = sfd;
   conn->state = MONGOC_CONN_STATE_ESTABLISHED;

   return TRUE;
}


bson_bool_t
mongoc_conn_connect (mongoc_conn_t *conn,
                     bson_error_t  *error)
{
   bson_return_val_if_fail(conn, FALSE);

   if (conn->state != MONGOC_CONN_STATE_INITIAL) {
      bson_set_error(error,
                     MONGOC_ERROR_CONN,
                     MONGOC_ERROR_CONN_INVALID_TYPE,
                     "%s() cannot be called twice.",
                     __FUNCTION__);
      return FALSE;
   }

   switch (conn->type) {
   case MONGOC_CONN_TCP:
      return mongoc_conn_connect_tcp(conn, error);
   case MONGOC_CONN_UNIX:
      // TODO:
      break;
   case MONGOC_CONN_FD:
      // TODO:
      break;
   default:
      bson_set_error(error,
                     MONGOC_ERROR_CONN,
                     MONGOC_ERROR_CONN_INVALID_STATE,
                     "No such connection type: %02x",
                     conn->type);
      return FALSE;
   }

   return TRUE;
}


void
mongoc_conn_destroy (mongoc_conn_t *conn)
{
   bson_return_if_fail(conn);
}
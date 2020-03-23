{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- | Special Zettel links in Markdown
module Neuron.Zettelkasten.Link.View where

import Lucid
import Neuron.Zettelkasten.ID
import Neuron.Zettelkasten.Link.Action
import Neuron.Zettelkasten.Route (Route (..))
import Neuron.Zettelkasten.Store
import Neuron.Zettelkasten.Type
import Relude
import qualified Rib

linkActionRender :: Monad m => ZettelStore -> MarkdownLink -> LinkAction -> HtmlT m ()
linkActionRender store MarkdownLink {..} = \case
  LinkAction_ConnectZettel _conn -> do
    -- The inner link text is supposed to be the zettel ID
    let zid = parseZettelID markdownLinkText
    renderZettelLink LinkTheme_Default store zid
  LinkAction_QueryZettels _conn linkTheme q -> do
    toHtmlRaw @Text $ "<!--" <> show q <> "-->"
    let zettels = reverse $ sortOn zettelIDDate $ runQuery store q
    ul_ $ do
      forM_ zettels $ \zid -> do
        li_ $ renderZettelLink linkTheme store zid

renderZettelLink :: forall m. Monad m => LinkTheme -> ZettelStore -> ZettelID -> HtmlT m ()
renderZettelLink ltheme store zid = do
  let Zettel {..} = lookupStore zid store
      zurl = Rib.routeUrlRel $ Route_Zettel zid
      renderDefault :: ToHtml a => a -> HtmlT m ()
      renderDefault linkInline = do
        span_ [class_ "zettel-link"] $ do
          span_ [class_ "zettel-link-idlink"] $ do
            a_ [href_ zurl] $ toHtml linkInline
          span_ [class_ "zettel-link-title"] $ do
            toHtml $ zettelTitle
  case ltheme of
    LinkTheme_Default -> do
      -- Special consistent styling for Zettel links
      -- Uses ZettelID as link text. Title is displayed aside.
      renderDefault zid
    LinkTheme_WithDate -> do
      renderDefault $ show @Text $ zettelIDDate zid
    LinkTheme_Simple ignoreZid -> do
      -- A normal looking link.
      -- Zettel's title is the link text.
      if Just zid == ignoreZid
        then renderActiveLink (unZettelID zid) zettelTitle
        else renderLink zurl (unZettelID zid) zettelTitle

renderLink :: forall a m. (Monad m, ToHtml a) => Text -> Text -> a -> HtmlT m ()
renderLink url title label =
  a_ [class_ "zettel-link item", href_ url, title_ title] $ do
    span_ [class_ "zettel-link-title"] $ do
      toHtml label

renderActiveLink :: forall a m. (Monad m, ToHtml a) => Text -> a -> HtmlT m ()
renderActiveLink title label =
  div_ [class_ "zettel-link item active", title_ title] $ do
    span_ [class_ "zettel-link-title"] $ do
      b_ $ toHtml label
